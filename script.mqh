


/*
   This file contains a script for a generic Standard Score Mean Reversion trading strategy. 
   
   Sends a BUY signal when spread is lower than minimum threshold,
   and a SELL signal when spread is higher than maximum threshold. 
   
   DISCLAIMER: This script does not guarantee future profits, and is 
   created for demonstration purposes only. Do not use this script 
   with live funds. 
*/


#include <B63/Generic.mqh> 
#include "trade_ops.mqh"

enum ENUM_SIGNAL {
   SIGNAL_LONG,
   SIGNAL_SHORT,
   SIGNAL_NONE
}; 


input int      InpMagic                   = 111111;
input int      InpSpreadPeriod            = 10;
input double   InpSpreadThreshold         = 2; 


class CMeanReversionTrade : public CTradeOps {
private:
   int      spread_period_; 
   double   spread_upper_threshold_, spread_lower_threshold_; 

public:
   CMeanReversionTrade();
   ~CMeanReversionTrade(); 
   
            int               SpreadPeriod() const { return spread_period_; }
            double            SpreadUpper()  const { return spread_upper_threshold_; }
            double            SpreadLower()  const { return spread_lower_threshold_; }
            
            void              Stage();
            ENUM_SIGNAL       Signal();
            double            SpreadValue(); 
            int               SendOrder(ENUM_SIGNAL signal);
            int               ClosePositions(ENUM_ORDER_TYPE order_type);
            bool              DeadlineReached(); 
}; 

CMeanReversionTrade::CMeanReversionTrade()
   : CTradeOps(Symbol(), InpMagic)
   , spread_period_(InpSpreadPeriod)
   , spread_upper_threshold_(MathAbs(InpSpreadThreshold))
   , spread_lower_threshold_(-MathAbs(InpSpreadThreshold)) {}
   

CMeanReversionTrade::~CMeanReversionTrade() {}

bool           CMeanReversionTrade::DeadlineReached() {
   return UTIL_TIME_HOUR(TimeCurrent()) >= 20; 
}

double         CMeanReversionTrade::SpreadValue() {
   return iCustom(
      NULL,
      PERIOD_CURRENT,
      "\\b63\\statistics\\z_score",
      SpreadPeriod(),
      0, 
      0, 
      1
   );
}

void           CMeanReversionTrade::Stage() {
   if (DeadlineReached()) {
      ClosePositions(ORDER_TYPE_BUY);
      ClosePositions(ORDER_TYPE_SELL);
      return;
   }
   
   ENUM_SIGNAL signal = Signal();
   if (signal == SIGNAL_NONE) return;
   SendOrder(signal); 
}

ENUM_SIGNAL    CMeanReversionTrade::Signal() {
   double spread_value  = SpreadValue();
   if (spread_value > SpreadUpper()) return SIGNAL_SHORT;
   if (spread_value < SpreadLower()) return SIGNAL_LONG;
   return SIGNAL_NONE;
}

int            CMeanReversionTrade::SendOrder(ENUM_SIGNAL signal) {
   ENUM_ORDER_TYPE   order_type;
   double entry_price;
   switch(signal) {
      case SIGNAL_LONG: 
         order_type  = ORDER_TYPE_BUY;
         entry_price = UTIL_PRICE_ASK(); 
         ClosePositions(ORDER_TYPE_SELL);
         break;
      case SIGNAL_SHORT:
         order_type  = ORDER_TYPE_SELL; 
         entry_price = UTIL_PRICE_BID();
         ClosePositions(ORDER_TYPE_BUY); 
         break;
      case SIGNAL_NONE:
         return -1;
      default:
         return -1; 
   }
   return OP_OrderOpen(Symbol(), order_type, 0.01, entry_price, 0, 0, NULL); 
}

int            CMeanReversionTrade::ClosePositions(ENUM_ORDER_TYPE order_type) {
   if (PosTotal() == 0) return 0; 
   
   CPoolGeneric<int> *tickets = new CPoolGeneric<int>(); 
   
   for (int i = 0; i < PosTotal(); i++) {
      int s = OP_OrderSelectByIndex(i);
      int ticket = PosTicket();
      if (!OP_TradeMatchTicket(ticket)) continue; 
      if (PosOrderType() != order_type) continue; 
      tickets.Append(ticket); 
   }
   int extracted[]; 
   int num_extracted = tickets.Extract(extracted); 
   OP_OrdersCloseBatch(extracted); 
   delete tickets;
   return num_extracted;
}

CMeanReversionTrade     mean_reversion_trade; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (IsNewCandle()) {
      mean_reversion_trade.Stage(); 
   }
   
  }
//+------------------------------------------------------------------+
