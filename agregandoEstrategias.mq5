#include <Trade/Trade.mqh>

CTrade trade;

input ENUM_TIMEFRAMES timeframe = PERIOD_M5;
input double lots = 0.1;
double accountBalance;
double middelBandArray[], upperBandArray[], lowBandArray[];
double middelBandValue, upperBandValue, lowBandValue;
int Rsi;
double RSI[], RSIvalue;
double ask, bid;
double actualPrice;
int bollingerBans, ema;
double TpFactor = 3.33;

int OnInit() {
    accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    bollingerBans = iBands(_Symbol, timeframe, 20, 0, 2, PRICE_CLOSE);
    ema = iMA(_Symbol, timeframe, 14, 0, MODE_EMA, PRICE_CLOSE);
    Rsi=iRSI(_Symbol,timeframe,14,PRICE_CLOSE);

    ArrayResize(middelBandArray, 3);
    ArrayResize(upperBandArray, 3);
    ArrayResize(lowBandArray, 3);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {

    ArraySetAsSeries(RSI,true);
    CopyBuffer(Rsi,0,0,3,RSI);
    RSIvalue=NormalizeDouble(RSI[0],_Digits);
    
    ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    actualPrice = iClose(_Symbol, timeframe, 0);

    ArraySetAsSeries(middelBandArray, true);
    ArraySetAsSeries(upperBandArray, true);
    ArraySetAsSeries(lowBandArray, true);

    if (CopyBuffer(bollingerBans, 0, 0, 3, middelBandArray) <= 0 ||
        CopyBuffer(bollingerBans, 1, 0, 3, upperBandArray) <= 0 ||
        CopyBuffer(bollingerBans, 2, 0, 3, lowBandArray) <= 0) {
        Print("Failed to get Bollinger Bands data");
        return;
    }

    middelBandValue = NormalizeDouble(middelBandArray[0], _Digits);
    upperBandValue = NormalizeDouble(upperBandArray[0], _Digits);
    lowBandValue = NormalizeDouble(lowBandArray[0], _Digits);

    // Check for open trades to avoid multiple positions
    if (PositionsTotal() == 0) {
        if (RSIvalue<30 && ask < lowBandValue) {
            double sl = lowBandValue-0.00020;
            double tp = middelBandValue;
            bool result = trade.Buy(lots, _Symbol, ask, sl, tp);
            if (result) {
                Print("Buy order executed successfully");
            } else {
                int error = GetLastError();
                Print("Error executing buy order: ", error);
                ResetLastError();
            }
        } else if (RSIvalue>70 && bid > upperBandValue) {
            Print("sell signal...");
            double sl = upperBandValue+0.00020;
            double tp = middelBandValue;
            bool result = trade.Sell(lots, _Symbol, bid, sl, tp);
            if (result) {
                Print("Sell order executed successfully");
            } else {
                int error = GetLastError();
                Print("Error executing sell order: ", error);
                ResetLastError();
            }
        }
    }
}

// Función para obtener el saldo de la cuenta
double GetAccountBalance() {
    return AccountInfoDouble(ACCOUNT_BALANCE);
}

//una ves mejorada esta estrategia debo unirmo con el YoutubeOne para que empiece a ganar mas