
#include <RECURVE/utilities.mqh>


class CLogging {

private:
               bool     logging_allowed_, notification_allowed_, alert_allowed_; 
public:
   CLogging(bool logging, bool notify, bool alerts);
   ~CLogging(); 
            
   const       bool     LoggingAllowed()  const       { return logging_allowed_; }
   const       bool     NotificationAllowed() const   { return notification_allowed_; }
   const       bool     AlertAllowed() const          { return alert_allowed_; }
               
               void     Status(); 

   virtual     void     LogInformation(string message, string function, bool debug=false, bool notify=false); 
   virtual     void     LogDebugInformation(string message, string function); 
   virtual     void     LogNotification(string message); 
   virtual     void     LogAlert(string message); 
   virtual     void     LogError(string message, string function); 
   virtual     void     LogNotImplemented(string function); 

}; 



CLogging::CLogging(bool logging, bool notify, bool alerts)
   : logging_allowed_(logging)
   , notification_allowed_ (notify)
   , alert_allowed_ (alerts) {}

CLogging::~CLogging() {}

void        CLogging::Status() {
   PrintFormat("Logging Allowed: %s, Notification Allowed: %s, Alert Allowed: %s", 
      (string)LoggingAllowed(), 
      (string)NotificationAllowed(), 
      (string)AlertAllowed()); 
}

void        CLogging::LogInformation(string message, string function, bool debug=false, bool notify=false) {
   if (!LoggingAllowed()) return; 
   if (debug) {
      LogDebugInformation(message, function); 
      return; 
   }
   
   PrintFormat("LOGGER - %s: %s", function, message); 
}

void        CLogging::LogDebugInformation(string message,string function) {
   
   PrintFormat("DEBUGGER - %s: %s", function, message); 
}

void        CLogging::LogNotification(string message) {
   if (UTIL_IS_TESTING()) return; 
   if (!NotificationAllowed()) return; 
   ResetLastError(); 
   
   if (!SendNotification(message)) LogInformation(StringFormat("Failed to send notification. Code: %i", GetLastError()), __FUNCTION__);  
}

void        CLogging::LogAlert(string message) {
   if (!AlertAllowed()) return; 
   Alert(message); 
}

void        CLogging::LogError(string message, string function) {
   ResetLastError(); 
   PrintFormat("ERROR - %s: Code: %i, Message: %s", function, GetLastError(), message);
}

void        CLogging::LogNotImplemented(string function) {
   PrintFormat("%s: Function not implemented.", __FUNCTION__); 
}