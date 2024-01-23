import { LightningElement, api } from 'lwc';

export default class CustomModal extends LightningElement {
    @api headerText = '';
    @api modalSize = 'medium';

    isModalOpen = false;

    get modalClass() {
        return `slds-modal slds-modal_${this.modalSize} ${
            this.isModalOpen ? ' slds-fade-in-open' : ''
        }`;
    }

    get backdropClass() {
        return this.isModalOpen
            ? 'slds-backdrop slds-backdrop_open'
            : 'slds-backdrop';
    }

    @api
    openModal() {
        this.isModalOpen = true;
    }

    @api
    closeModal() {
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('modalclose'));
    }
}
