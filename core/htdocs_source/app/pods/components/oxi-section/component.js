import Component from '@glimmer/component';
import { action, set } from "@ember/object";
import { debug } from '@ember/debug';
import { getOwner } from '@ember/application';

export default class OxiSectionComponent extends Component {
    get type() {
        return `oxi-section/${this.args.content.type}`;
    }

    get sectionData() {
        return {
            ...this.args.content.content,
            // map some inconsistently placed properties into the section data
            action:     this.args.content.action,       // used by oxisection/form
            reset:      this.args.content.reset,        // used by oxisection/form
            className:  this.args.content.className,    // used by oxisection/grid
        }
    }

    @action
    buttonClick(button) {
        debug("oxisection/main: buttonClick");
        set(button, "loading", true);
        if (button.action) {
            getOwner(this).lookup("route:openxpki")
            .sendAjax({ action: button.action })
            .finally(() => set(button, "loading", false));
        }
        else {
            getOwner(this).lookup("route:openxpki").transitionTo("openxpki", button.page);
        }
    }
}
