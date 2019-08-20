#!/usr/bin/perl
#
# Test if a background workflow (i.e. forking) works in conjunction with a
# workflow action that calls Proc::SafeExec.
# Previously, there have been problems with SIGCHLD, see Github issue #517.
#
use strict;
use warnings;

# Core modules
use English;
use FindBin qw( $Bin );

# CPAN modules
use Test::More;
use Test::Deep;
use Test::Exception;
use DateTime;

# Project modules
use lib "$Bin/lib", "$Bin/../lib", "$Bin/../../core/server/t/lib";
use OpenXPKI::Test;


# plan tests => 14; WE CANNOT PLAN tests as there is a while loop that sends commands (which are tests)


#
# Setup test context
#
sub workflow_def {
    my ($name) = @_;
    (my $cleanname = $name) =~ s/[^0-9a-z]//gi;
    return {
        'head' => {
            'label' => $name,
            'persister' => 'OpenXPKI',
            'prefix' => $cleanname,
        },
        'state' => {
            'INITIAL' => {
                'action' => [ 'initialize > BACKGROUNDING' ],
            },
            'BACKGROUNDING' => {
                'autorun' => 1,
                'action' => [ 'pause_before_fork > LOITERING' ],
            },
            'LOITERING' => {
                'autorun' => 1,
                'action' => [ 'do_something > SUCCESS' ],
            },
            'SUCCESS' => {
                'label' => 'I18N_OPENXPKI_UI_WORKFLOW_SET_MOTD_SUCCESS_LABEL',
                'description' => 'I18N_OPENXPKI_UI_WORKFLOW_SET_MOTD_SUCCESS_DESCRIPTION',
                'output' => [ 'message', 'link', 'role' ],
            },
            'FAILURE' => {
                'label' => 'Workflow has failed',
            },
        },
        'action' => {
            'initialize' => {
                'class' => 'OpenXPKI::Server::Workflow::Activity::Noop',
                'label' => 'I18N_OPENXPKI_UI_WORKFLOW_ACTION_MOTD_INITIALIZE_LABEL',
                'description' => 'I18N_OPENXPKI_UI_WORKFLOW_ACTION_MOTD_INITIALIZE_DESCRIPTION',
            },
            'do_something' => {
                'class' => 'OpenXPKI::Test::Is13Prime',
            },
            'pause_before_fork' => {
                'class' => 'OpenXPKI::Server::Workflow::Activity::Tools::Disconnect',
                'param' => { 'pause_info' => 'We want this to be picked up by the watchdog' },
            },
        },
        'field' => {},
        'validator' => {},
        'acl' => {
            'CA Operator' => { creator => 'any', techlog => 1, history => 1 },
        },
    };
};

my $oxitest = OpenXPKI::Test->new(
    with => [ "SampleConfig", "Server", "Workflows" ],
    also_init => "crypto_layer",
    start_watchdog => 1,
    add_config => {
        "realm.democa.workflow.def.wf_type_1" => workflow_def("wf_type_1"),
    },
);

my $tester = $oxitest->new_client_tester;
$tester->login("democa" => "caop");

sub wait_for_proc_state {
    my ($wfid, $state_regex) = @_;
    my $testname = "Waiting for workflow state $state_regex";
    my $result;
    my $count = 0;
    while ($count++ < 20) {
        $result = $tester->send_command_ok("search_workflow_instances" => { id => [ $wfid ] });
        # no workflow found?
        if (not scalar @$result or $result->[0]->{'workflow_id'} != $wfid) {
            BAIL_OUT("Workflow with ID $wfid not found");
        }
        # wait if paused (i.e. resuming in progress) or still running (the remaining steps)
        if (not $result->[0]->{'workflow_proc_state'} =~ $state_regex) {
            sleep 1;
            next;
        }
        # expected proc state reached
        ok $testname;
        return $result;
    }
    BAIL_OUT("Timeout reached while waiting for workflow to reach state $state_regex");
}
my $result;

lives_and {
    $result = $tester->send_command_ok("create_workflow_instance" => {
        workflow => "wf_type_1",
    });
} "create_workflow_instance()";

my $wf = $result->{workflow} or BAIL_OUT('Workflow data not found');
my $wf_id = $wf->{id} or BAIL_OUT('Workflow ID not found');

##diag explain OpenXPKI::Workflow::Config->new->workflow_config;

#
# wait for wakeup by watchdog
#
note "waiting for backgrounded (forked) workflow to finish";
$result = wait_for_proc_state $wf_id, qr/^(finished|exception)$/;

# compare result
cmp_deeply $result, [ superhashof({
    'workflow_id' => $wf_id,
    'workflow_proc_state' => 'finished', # could be 'exception' if things go wrong
    'workflow_state' => 'SUCCESS',
}) ], "Workflow finished successfully" or diag explain $result;

#
# get_workflow_info - check action results
#
lives_and {
    $result = $tester->send_command_ok("get_workflow_info" => { id => $wf_id });
    cmp_deeply $result->{workflow}->{context}->{is_13_prime}, 1;
} "Workflow action returns correct result";

#
# get_workflow_history - check correct execution history
#
lives_and {
    $result = $tester->send_command_ok("get_workflow_history" => { id => $wf_id });
    cmp_deeply $result, [
        superhashof({ workflow_state => "INITIAL", workflow_action => re(qr/create/i) }),
        superhashof({ workflow_state => "INITIAL", workflow_action => re(qr/initialize/i) }),
        superhashof({ workflow_state => "BACKGROUNDING", workflow_action => re(qr/pause_before_fork/i) }), # pause
        superhashof({ workflow_state => "BACKGROUNDING", workflow_action => re(qr/pause_before_fork/i) }), # wakeup
        superhashof({ workflow_state => "BACKGROUNDING", workflow_action => re(qr/pause_before_fork/i) }), # state change
        superhashof({ workflow_state => "LOITERING", workflow_action => re(qr/do_something/i) }),
    ] or diag explain $result;
} "get_workflow_history()";

$oxitest->stop_server;

done_testing;

1;
