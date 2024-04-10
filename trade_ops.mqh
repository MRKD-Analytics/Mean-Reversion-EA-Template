
#include <RECURVE/utilities.mqh>
#include "pool.mqh"
#include "logging.mqh"

#ifdef __MQL5__ 
#include <Trade/Trade.mqh>
CTrade Trade; 
#endif 
class CTradeOps {
   private:
      string      TRADE_SYMBOL;
      int         TRADE_MAGIC;
      
   protected:
      CLogging    *Log_; 
                  
   public: 
      CTradeOps(string symbol, int magic); 
      ~CTradeOps();
      
      
                  void              SYMBOL(string symbol)   { TRADE_SYMBOL = symbol; }
                  void              MAGIC(int magic)        { TRADE_MAGIC  = magic; }
                  
                  string            SYMBOL(void) const      { return TRADE_SYMBOL; }
                  int               MAGIC(void) const       { return TRADE_MAGIC; }
                  //--- WRAPPERS
                  #ifdef __MQL4__
                  double            PosLots(void) const     { return OrderLots(); }
                  string            PosSymbol(void) const   { return OrderSymbol(); }
                  int               PosMagic(void) const    { return OrderMagicNumber(); }
                  datetime          PosOpenTime() const     { return OrderOpenTime(); }
                  datetime          PosCloseTime() const    { return OrderCloseTime(); }
                  double            PosOpenPrice() const    { return OrderOpenPrice(); }
                  double            PosClosePrice() const   { return OrderClosePrice(); }
                  double            PosProfit() const       { return (OrderProfit() + OrderCommission() + OrderSwap()); }
                  ENUM_ORDER_TYPE   PosOrderType() const    { return (ENUM_ORDER_TYPE)OrderType(); }
                  double            PosSL() const           { return OrderStopLoss(); }
                  double            PosTP() const           { return OrderTakeProfit(); }
                  double            PosCommission() const   { return MathAbs(OrderCommission()); }
                  double            PosSwap() const         { return MathAbs(OrderSwap()); }
                  int               PosHistTotal() const    { return OrdersHistoryTotal(); }
                  string            PosComment() const      { return OrderComment(); }
                  
                  int               PosTotal(void) const    { return OrdersTotal(); }
                  int               PosTicket(void) const   { return OrderTicket(); }
                  #endif 
                  
                  #ifdef __MQL5__ 
                  double            PosLots() const         { return PositionGetDouble(POSITION_VOLUME); } 
                  string            PosSymbol() const       { return PositionGetString(POSITION_SYMBOL); }
                  int               PosMagic() const        { return (int)PositionGetInteger(POSITION_MAGIC); }
                  datetime          PosOpenTime() const     { return (datetime)PositionGetInteger(POSITION_TIME); }
                  datetime          PosCloseTime() const    { return 0; } // temporary
                  double            PosOpenPrice() const    { return PositionGetDouble(POSITION_PRICE_OPEN); }
                  double            PosClosePrice()          { return 0; }
                  double            PosProfit() const       { return PositionGetDouble(POSITION_PROFIT); }
                  ENUM_ORDER_TYPE   PosOrderType() const    { return (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE); }
                  double            PosSL() const           { return PositionGetDouble(POSITION_SL); }
                  double            PosTP() const           { return PositionGetDouble(POSITION_TP); }
                  string            PosComment() const      { return "";}
                  int               OrdersHistTotal() const { return HistoryOrdersTotal(); }
                  int               DealsHistTotal() const  { return HistoryDealsTotal(); }
                  
                  int               PosTotal() const        { return PositionsTotal(); }
                  int               PosTicket() const       { return (int)PositionGetInteger(POSITION_TICKET); }
                  
                  #endif 
      
      #ifdef __MQL4__             
      virtual     int               OP_OrderSelectByTicket(int ticket) const     { return OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); }
      virtual     int               OP_OrderSelectByIndex(int index) const       { return OrderSelect(index, SELECT_BY_POS, MODE_TRADES); }
      virtual     int               OP_HistorySelectByIndex(int index) const     { return OrderSelect(index, SELECT_BY_POS, MODE_HISTORY); }
      virtual     int               OP_HistorySelectByTicket(int ticket) const   { return OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY); }
      #endif 
      
      #ifdef __MQL5__ 
      virtual     int               OP_OrderSelectByTicket(int ticket) const     { return PositionSelectByTicket(ticket); } 
      virtual     int               OP_OrderSelectByIndex(int index) const       { return PositionSelectByTicket(PositionGetTicket(index)); }
      //--- TODO 
      virtual     int               OP_HistorySelectByIndex(int index) const     { return 0; }
      virtual     int               OP_HistorySelectByTicket(int ticket) const   { return 0; }
      
      #endif 
      //--- TRADE OPERATIONS
      virtual     int      OP_OrdersCloseAll(); 
      virtual     bool     OP_CloseTrade(int ticket);
      virtual     int      OP_OrderOpen(string symbol, ENUM_ORDER_TYPE order_type, double volume, double price, double sl, double tp, string comment, datetime expiration = 0); 
      virtual     bool     OP_TradeMatch(int index);
      virtual     bool     OP_TradeMatchTicket(int ticket); 
     
      virtual     int      OP_ModifySL(int ticket, double sl); 
     
      
      virtual     int      OP_ModifyTP(double tp);
      virtual     int      OP_OrdersCloseBatch(int &orders[]); 
      virtual     int      OP_OrdersBreakevenBatch(int &orders[]); 
      
      //--- MISC FUNCTIONS
      virtual     bool     OrderIsPending(int ticket); 
      virtual     int      PopOrderArray(int &tickets[]); 
      virtual     bool     OrderTypeIsPending(ENUM_ORDER_TYPE order); 
      
      

};     

CTradeOps::CTradeOps(string symbol, int magic) 
   : TRADE_SYMBOL(symbol)
   , TRADE_MAGIC (magic) {
   Log_ = new CLogging(true, false, false); 
   #ifdef __MQL5__ 
   Trade.SetExpertMagicNumber(TRADE_MAGIC); 
   #endif 
} 

CTradeOps::~CTradeOps(void) {
   delete Log_; 
}

bool       CTradeOps::OP_CloseTrade(int ticket) {
   ResetLastError();
   int   t     = OP_OrderSelectByTicket(ticket);  
   double   close_price = 0;
   ENUM_ORDER_TYPE   order_type  = PosOrderType();
   
   switch(order_type) {
      case ORDER_TYPE_BUY:    close_price = UTIL_PRICE_BID();  break;
      case ORDER_TYPE_SELL:   close_price = UTIL_PRICE_ASK();  break; 
      
   }
   
   bool c;
   switch(order_type) {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         #ifdef __MQL4__ 
         c  = OrderClose(PosTicket(), PosLots(), close_price, 3);
         #endif 
         
         #ifdef __MQL5__ 
         c  = Trade.PositionClose(ticket);
         #endif
         if (!c) Log_.LogError(StringFormat("Order Close Failed. Ticket: %i, Error: %i", 
            PosTicket(), 
            GetLastError()), __FUNCTION__); 
         break; 
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_LIMIT:
         #ifdef __MQL4__ 
         c  = OrderDelete(PosTicket()); 
         #endif 
         
         #ifdef __MQL5__ 
         c = Trade.OrderDelete(ticket); 
         #endif 
         if (!c) Log_.LogError(StringFormat("Order Delete Failed. Ticket: %i, Error: %i",
            PosTicket(),
            GetLastError()), __FUNCTION__);
         break; 
      default:
         c = 0;
         break; 
   }
   return c;    
}


int      CTradeOps::OP_OrderOpen(
   string symbol,
   ENUM_ORDER_TYPE order_type,
   double volume,
   double price,
   double sl,
   double tp,
   string comment,
   datetime expiration=0) {
      //--- Validate inputs 
      
      #ifdef __MQL4__ 
      int ticket = OrderSend(Symbol(), order_type, NormalizeDouble(volume, 2), price, 3, sl, tp, comment, MAGIC(), expiration);
      #endif 
      
      #ifdef __MQL5__
      // TODO: PENDING ORDERS
      
      int result; 
      switch(OrderTypeIsPending(order_type)) {
         case true:
            switch(order_type) {
               case ORDER_TYPE_BUY_STOP_LIMIT:
               case ORDER_TYPE_SELL_STOP_LIMIT: 
                  Log_.LogInformation("Order functions for this order type is not yet implemented.", __FUNCTION__);
                  return 0;
            }
            result = Trade.OrderOpen(symbol, order_type, NormalizeDouble(volume, 2), 0, price, sl, tp, ORDER_TIME_GTC, expiration, comment); 
         case false:  
            result = Trade.PositionOpen(symbol, order_type, NormalizeDouble(volume, 2), price, sl, tp, comment); 
            break; 
      }
      
      ulong ret_code = Trade.ResultRetcode(); 
      ulong ticket = Trade.ResultDeal(); 
      switch(ret_code == TRADE_RETCODE_DONE) {
         case true:
            Log_.LogInformation(StringFormat("Order Send Successful. Ticket: %i, Price: %f, Volume: %.2f, SL: %f, TP: %f",
               ticket, 
               UTIL_TO_PRICE(Trade.RequestPrice()),
               Trade.RequestVolume(),
               UTIL_TO_PRICE(Trade.RequestSL()), 
               UTIL_TO_PRICE(Trade.RequestTP())), __FUNCTION__); 
            break;
         case false: 
            Log_.LogError(StringFormat("Position open error. Code: %i", ret_code), __FUNCTION__); 
            break;
      }
      
      #endif 
      return ticket; 
}

bool     CTradeOps::OrderTypeIsPending(ENUM_ORDER_TYPE order) {
   switch(order) {
      case ORDER_TYPE_BUY: 
      case ORDER_TYPE_SELL: 
         return false; 
      default: 
         break; 
   }
   return true; 
}

int      CTradeOps::OP_OrdersCloseAll(void) {
   /**
      Closes trades opened by the EA. Closes only set symbol and magic number 
   **/
   //--- Last Update 3/29/2024
   int open_positions   = PosTotal(); 
   CPoolGeneric<int> *tickets_to_close = new CPoolGeneric<int>(); 
   
   int s, ticket; 
   for (int i = 0; i < open_positions; i++) {
      s        = OP_OrderSelectByIndex(i); 
      ticket   = PosTicket();
      //if (!OP_TradeMatch(i)) continue;
      if (!OP_TradeMatchTicket(ticket)) continue; 
      tickets_to_close.Append(ticket);
   }
   
   /*
   int closed     = 0;
   for (int j = 0; j < tickets_to_close.Size(); j++) {
      bool c   = OP_CloseTrade(tickets_to_close.Item(j)); 
      if (c) closed++; 
   }*/
   
   int closed = 0, active_ticket;
   bool d; 
   while (tickets_to_close.Size() > 0) {
      //--- Unstack 
      active_ticket = tickets_to_close.First(); 
      d = OP_CloseTrade(active_ticket);
      tickets_to_close.Remove(active_ticket); 
      closed++;  
   }
   
   delete tickets_to_close; 
   return closed;    
}

int      CTradeOps::OP_OrdersCloseBatch(int &orders[]) {
   CPoolGeneric <int> *order_pool = new CPoolGeneric<int>(); 
   order_pool.Create(orders); 
   int num_orders = order_pool.Size(); 
   
   //--- Recursion base case 
   if (num_orders <= 0) {
      delete order_pool;
      return 0; 
   } 
   
   int ticket  = order_pool.Item(0); 
   
   bool c      = OP_CloseTrade(ticket); 
   if (c)   Log_.LogInformation(StringFormat("Trade Closed. Ticket: %i", ticket), __FUNCTION__); 
   int a       = order_pool.Dequeue(); 
   if (a > num_orders) {
      delete order_pool;
      return -1; 
   }
   
   int extracted[]; 
   int num_extracted = order_pool.Extract(extracted);
   
   delete order_pool; 
   return OP_OrdersCloseBatch(extracted); 
}

int      CTradeOps::OP_OrdersBreakevenBatch(int &orders[]) {
   CPoolGeneric<int> *order_pool = new CPoolGeneric<int>(); 
   order_pool.Create(orders);
   int num_orders = order_pool.Size();
   
   if (num_orders <= 0) {
      delete order_pool;
      return 0; 
   }
   int ticket = order_pool.Item(0); 
   //int s = OP_OrderSelectByTicket(ticket); 
   int m = OP_ModifySL(ticket, PosOpenPrice()); 
   int a = order_pool.Dequeue();
   if (a > num_orders) {
      delete order_pool;
      return -1;
   }
   
   int extracted[];
   int num_extracted = order_pool.Extract(extracted);
   
   delete order_pool;
   return OP_OrdersBreakevenBatch(extracted); 
}

int      CTradeOps::PopOrderArray(int &tickets[]) {
   int temp[]; 
   int size = ArraySize(tickets); 
   
   ArrayResize(temp, size-1); 
   ArrayCopy(temp, tickets, 0, 1); 
   ArrayFree(tickets); 
   ArrayCopy(tickets, temp);
   return ArraySize(tickets); 
}

bool     CTradeOps::OP_TradeMatch(int index) {
   
   int t = OP_OrderSelectByIndex(index); 
   if (PosMagic() != MAGIC()) return false;
   if (PosSymbol() != SYMBOL()) return false; 
   return true; 
}

bool     CTradeOps::OP_TradeMatchTicket(int ticket) {
   
   int t = OP_OrderSelectByTicket(ticket);
   if (PosMagic() != MAGIC()) return false; 
   if (PosSymbol() != SYMBOL()) return false; 
   return true;
}

bool     CTradeOps::OrderIsPending(int ticket) {
   int t = OP_OrderSelectByTicket(ticket); 
   if (PosOrderType() > 1) return true; 
   return false;
}

int      CTradeOps::OP_ModifySL(int ticket, double sl) {
   int b = OP_OrderSelectByTicket(ticket); 
   #ifdef __MQL4__ 
   int m = OrderModify(PosTicket(), PosOpenPrice(), sl, PosTP(), 0); 
   #endif 
   
   #ifdef __MQL5__ 
   int m = Trade.PositionModify(ticket, sl, PosTP()); 
   #endif 
   if (!m) Log_.LogError(StringFormat("Order Modify Error. Current SL: %f, Target SL: %f", PosSL(), sl), __FUNCTION__); 
   return m; 
}
