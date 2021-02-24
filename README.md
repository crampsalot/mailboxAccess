# mailboxAccess

Technical Assignment:

You’re part of a new and exciting project. The project will allow customers to track a package. Once it is delivered to your homes mailbox, you will be able to lock and unlock your mailbox with a mobile app - Assume your team also produced the hardware for the mailbox giving you full control. You will need to create the mobile app; your cloud infrastructure will be either AWS or Azure. Your application will use the mobile phones GPS for location and Bluetooth Low Energy (BLE) to control access to the mailbox.

1. Provide a structural UML class diagram of the mobile app (I.e. Classes, Interfaces, Components etc..)
2. Implement the the following functions as outlined by your UML diagram. Make any assumptions necessary - but please provide your assumptions, imports are not required. Please be specific to BLE and the OS of your choice (iOS or Android only).
 - Connect to a discovered Mailbox
 - Authenticate user
 - Send unlock command
 
 ---
  
 ## Assumptions
  - The User JSON/object, is obtained as part of authentication with the 'cloud infrastructure'. Code/classes for that is not implemented in this repository.
  - The physical mailbox is BLE enabled. It is a bluetooth peripheral device that broadcasts its name in the advertisement packets which the iOS app can use to determine which devices are of interest.
  - The mailbox has a bluetooth service with 2 characteristics.
  - The 'mailbox id' characteristic contains the ID of the mailbox which should match the mailbox id also in the 
  - The 'lock' characeristic can be written to which will cause the mailbox to be locked or unlocked.
  
  ## Classes
   - User. User object obtained as part of authentication with cloud
   - MailboxManager. Singleton Manager class that manages BLE operations/tasks
   - MailboxState. Enum for various states of MailboxManager. This is stored in the 'state' property of the MailboxManager object.
    - disconnected. Default state; not connected to mailbox.
    - conntected. Discovered and connected to mailbox.
    - authenticated. The mailbox id in the user profile (in User object) matches with the mailbox id. The app can proceed to lock/unlock the mailbox.
    - authFailed. The mailbox id in the user profile does NOT match with the mailbox id. The app cannot proceed to lock/unlock the mailbox.
    - locked. Locking the mailbox was successful
    - unlocked. Unlocking the mailbox was successful
   - MailboxDelegate. Delegate for MailboxManager. UI components can use this to determine when the mailbox is connected, and ready to be 
   
  ## Flow
   1. App shows login screen and uses entered credentials to obtain user Object from backend
   2. App calls connect() method of MailboxManager to connect to mailbox and verify that the mailbox id is correct.
   3. If it is, the app can present a UI to allow the user to lock/unlock the mailbox.

  ## UML Diagram
  ![UML Diagram](images/Mailbox.png)
