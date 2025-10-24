# Onl9Vet Doctor App Activity Diagram

## Overview
This activity diagram represents the main doctor workflows and system interactions in the Onl9Vet Doctor telemedicine application, designed specifically for veterinary professionals.

## PlantUML Code

```plantuml
@startuml Onl9Vet Doctor Activity Diagram

!theme plain
skinparam backgroundColor #FFFFFF
skinparam activity {
  BackgroundColor #FFF3E0
  BorderColor #FF9800
  FontColor #000000
}

title Onl9Vet Doctor - Veterinary Professional App Activity Diagram

start

:App Launch;
:Initialize Supabase & Google Sign-In;

if (Doctor Logged In?) then (yes)
  :Navigate to Main Navigation;
else (no)
  :Show Doctor Login Screen;
  
  fork
    :Email/Password Login;
    :Validate Doctor Credentials;
    if (Valid Doctor Account?) then (yes)
      :Authenticate Doctor;
    else (no)
      :Show Access Denied Error;
      stop
    endif
  fork again
    :Google Sign-In;
    :OAuth Authentication;
    if (Doctor Role Verified?) then (yes)
      :Create/Update Doctor Profile;
    else (no)
      :Show Access Denied Error;
      stop
    endif
  end fork
  
  :Navigate to Main Navigation;
endif

:Load Doctor Profile Data;
:Load Appointments & Patients;

partition "Main Doctor Navigation" {
  :Display Main Navigation Screen;
  
  fork
    :View Appointments;
    :Display Appointment List;
    :Search & Filter Appointments;
    
    if (Appointment Selected?) then (yes)
      :Show Appointment Details;
      
      partition "Appointment Management" {
        :Review Patient Information;
        :Review Pet Details;
        :Review Consultation Purpose;
        :Review Medical History;
        
        if (Action Required?) then (yes)
          fork
            :Confirm Appointment;
            :Update Status to Confirmed;
          fork again
            :Start Video Consultation;
            :Initialize Agora RTC;
            :Request Permissions;
            :Join Video Channel;
            :Conduct Video Consultation;
            :Enable Chat Feature;
            :Monitor Call Duration;
            if (Call Ended?) then (yes)
              :End Video Call;
              :Update Appointment Status;
              :Record Consultation Notes;
            else (no)
              :Continue Consultation;
            endif
          fork again
            :Mark as Completed;
            :Update Status to Completed;
            :Add Treatment Notes;
          fork again
            :Cancel Appointment;
            :Update Status to Cancelled;
            :Provide Cancellation Reason;
          end fork
        else (no)
          :View Appointment Info Only;
        endif
      }
    else (no)
      :Return to Appointments List;
    endif
  fork again
    :View Patients;
    :Display Patient List;
    :Search & Filter Patients;
    
    if (Patient Selected?) then (yes)
      :Show Patient Details;
      
      partition "Patient Management" {
        :View Patient Profile;
        :View Pet Information;
        :View Medical History;
        :View Previous Appointments;
        :View Treatment Records;
        :Add Medical Notes;
        :Update Patient Information;
      }
    else (no)
      :Return to Patients List;
    endif
  fork again
    :Access Profile & Settings;
    
    partition "Doctor Profile Management" {
      :View Doctor Profile;
      :Update Personal Information;
      :Manage Availability;
      :Update Specializations;
      :View Earnings & Statistics;
      
      partition "Settings Management" {
        :Manage Notifications;
        :Change Password;
        :Language Settings;
        :Privacy Settings;
        :App Preferences;
      }
    }
  end fork
}

partition "Appointment Scheduling" {
  if (Add New Appointment?) then (yes)
    :Show Add Appointment Form;
    :Select Patient;
    :Set Appointment Date/Time;
    :Add Consultation Notes;
    :Set Appointment Type;
    :Save Appointment;
    :Send Notification to Patient;
  else (no)
    :Skip Appointment Creation;
  endif
}

partition "Video Consultation Features" {
  if (Video Call Active?) then (yes)
    :Enable Screen Sharing;
    :Enable File Sharing;
    :Enable Chat Messaging;
    :Record Consultation;
    :Take Screenshots;
    :Manage Call Controls;
    if (Emergency Detected?) then (yes)
      :Show Emergency Protocols;
      :Provide Emergency Guidance;
      :Escalate to Emergency Care;
    else (no)
      :Continue Normal Consultation;
    endif
  else (no)
    :Prepare for Consultation;
  endif
}

partition "Medical Records Management" {
  :Update Patient Records;
  :Add Treatment Plans;
  :Prescribe Medications;
  :Schedule Follow-ups;
  :Generate Medical Reports;
  :Share Records with Patient;
}

partition "Professional Features" {
  :View Consultation History;
  :Access Medical References;
  :Manage Work Schedule;
  :View Performance Analytics;
  :Handle Patient Inquiries;
  :Professional Development;
}

:Update Doctor Session;
:Save Preferences & Settings;
:Sync Data with Backend;

stop

@enduml
```

## Key Doctor Workflows

### 1. Authentication & Authorization
- **Doctor-Specific Login**: Role-based authentication for veterinary professionals
- **Access Control**: Verification of doctor credentials and permissions
- **Profile Management**: Doctor-specific profile and settings

### 2. Appointment Management
- **Appointment Dashboard**: Overview of all scheduled consultations
- **Appointment Details**: Comprehensive view of patient and pet information
- **Status Management**: Confirm, start, complete, or cancel appointments
- **Search & Filter**: Advanced filtering by status, date, patient, etc.

### 3. Patient Management
- **Patient Database**: Complete patient and pet records
- **Medical History**: Access to previous consultations and treatments
- **Patient Profiles**: Detailed information about pets and owners
- **Record Updates**: Add notes, treatments, and follow-up plans

### 4. Video Consultation System
- **Agora RTC Integration**: Professional-grade video calling
- **Consultation Tools**: Screen sharing, file sharing, chat messaging
- **Call Management**: Start, monitor, and end consultations
- **Emergency Protocols**: Handle emergency situations appropriately

### 5. Medical Records & Documentation
- **Treatment Plans**: Create and manage treatment protocols
- **Prescriptions**: Generate medication prescriptions
- **Medical Notes**: Document consultation findings and recommendations
- **Follow-up Scheduling**: Plan and schedule follow-up appointments

### 6. Professional Features
- **Performance Analytics**: View consultation statistics and earnings
- **Work Schedule**: Manage availability and working hours
- **Medical References**: Access veterinary resources and guidelines
- **Professional Development**: Track continuing education and certifications

## Technical Components

### Backend Services
- **Supabase**: Authentication, database, and real-time data
- **Agora**: Professional video calling infrastructure
- **Firebase**: Additional data storage and analytics
- **Google Sign-In**: OAuth authentication for doctors

### Key Features
- **Role-Based Access**: Doctor-specific authentication and permissions
- **Real-time Video Consultation**: Professional Agora RTC integration
- **Patient Records Management**: Comprehensive medical record system
- **Appointment Scheduling**: Advanced scheduling and management tools
- **Professional Dashboard**: Analytics and performance tracking

## Data Flow
1. **Doctor Authentication** → **Role Verification** → **Access Grant**
2. **Appointment Review** → **Patient Assessment** → **Treatment Planning**
3. **Video Consultation** → **Real-time Communication** → **Medical Documentation**
4. **Patient Records** → **Data Updates** → **Information Synchronization**
5. **Professional Analytics** → **Performance Tracking** → **Report Generation**

## Security & Compliance
- **HIPAA Compliance**: Secure handling of medical information
- **Role-Based Security**: Doctor-specific access controls
- **Data Encryption**: Secure transmission and storage of patient data
- **Audit Trails**: Complete logging of all medical activities

This activity diagram provides a comprehensive view of the Onl9Vet Doctor app's functionality, showing how veterinary professionals interact with the system to provide telemedicine services, manage patients, and maintain professional standards in veterinary care. 