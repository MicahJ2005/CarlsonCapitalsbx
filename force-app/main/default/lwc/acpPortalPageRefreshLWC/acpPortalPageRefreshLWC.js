import { LightningElement, api } from 'lwc';

export default class AcpPortalPageRefreshLWC extends LightningElement {
    @api NewOrClone;
    @api New_Grant;
    @api Cloned_Grant;

    showNotification = false;
    _title = 'Success!';
    message = 'Your "New Grant Request" has been created';
    variant = 'success';

    connectedCallback(){
        console.log('In AcpPortalPageRefreshLWC connectedCallback');
        console.log('In AcpPortalPageRefreshLWC NewOrClone: ', this.NewOrClone);
        this.showNotification = true;
        // showNotification() {
            // const evt = new ShowToastEvent({
            //     title: this._title,
            //     message: this.message,
            //     variant: this.variant,
            //     mode: 'sticky',
            // });
            // this.dispatchEvent(evt);
        // }
    }

    navigateHome(){
        this.showNotification = false;
        window.open('/ACPPortal/s/', '_self')
    }

}