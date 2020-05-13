import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import startRegistration from '@salesforce/apex/PersistentLoginController.startVerificationProcessForSignUp';
import confirmRegistration from '@salesforce/apex/PersistentLoginController.confirmRegistration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PasswordlessRegistraton extends NavigationMixin(LightningElement) {

  email = '';
  code = '';
  identifier = '';
  userId = '';
  lastname = '';
  firstname = '';

  handleChange(event) {
    if (event.target.label === 'email') {
      this.email = event.target.value;
    }
    if (event.target.label === 'Code') {
      this.code = event.target.value;
    }
    if (event.target.label === 'First Name') {
      this.firstname = event.target.value;
    }
    if (event.target.label === 'Last Name') {
      this.lastname = event.target.value;
    }
  }

  register() {
    startRegistration({ firstname: this.firstname, lastname: this.lastname, email: this.email })
      .then(result => {
        console.log(result);
        console.log(result.statusCode);
        //let data = JSON.parse(result);
        //this.userId = data.userId;
        //this.identifier = data.identifier;
      })
      .catch(error => {
        console.log(error);
      })
  }
  confirm() {
    confirmRegistration({ identifier: this.identifier, code: this.code })
      .then(result => {
        console.log(result);
        this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: {
            url: result
          }
        });
      })
      .catch(error => {
        console.log(error);
      })
  }
  showToast(msg) {
    const evt = new ShowToastEvent({
      title: 'self registration',
      message: msg,
      variant: 'info',
    });
    this.dispatchEvent(evt);
  }
}
