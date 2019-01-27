clc;

decision = input('Choose the mode of display:\n 1. Predictor\n 2. Comparison\n','s');

if strcmpi(decision,'2')

    clear marketData;
    startdate = input('Enter starting date: (ex: 1-Jan-2018)\n','s');
    enddate = input('Enter ending date: (ex: 15-Feb-2018)\n','s');
    if strcmpi(startdate,"")
        startdate = datetime('01-Jan-2018'); 
    end
    if(strcmpi(enddate,'') || round(datenum((datetime(enddate) - startdate))) < 0)
        enddate = datetime('now'); 
    end
    symbols = split(input('Enter each ticker symbol (ex: TSLA DIS NKE)\n','s'));
    for k = 1:length(symbols)
        data = getMarketDataViaYahoo(symbols{k}, startdate, enddate);
        ts(k) = timeseries(data.Close, datestr(data(:,1).Date));
        tsout = resample(ts(k),ts(1).Time);
        marketData(:,k) = tsout.Data;
    end

    marketData(isnan(marketData)) = 0; % In case resample() introduced NaNs
    tscomb = timeseries(marketData);
    tscomb.TimeInfo = ts(1).TimeInfo;
    tscomb.Name = 'Price';
    for symbol = 1:length(symbols)
        symbols{symbol} = upper(symbols{symbol});
    end
    figure, plot(tscomb);
    title('Stock Comparison');
    xlabel('Date');
    ylabel('Price');
    legend(symbols, 'interpreter', 'none', 'Location', 'northwest');
   
elseif strcmpi(decision,'1')
    
    startdate = input('Enter start date In Format (i.e 01-Jan-2017):\n','s');
    enddate = input('Enter end date In Format (i.e 12-Feb-2018):\n','s');
    
    if strcmpi(startdate,'')
        startdate = datetime('01-Jan-2018'); 
    end

    if(strcmpi(enddate,'') || round(datenum((datetime(enddate) - startdate))) < 0)
        enddate = datetime('now'); 
    end
    symbol=input('Enter Stock Symbol\n','s');

    timeGap = round(datenum((datetime(enddate) - startdate)));
    stock = getMarketDataViaYahoo(symbol, startdate, enddate);
    temp = zeros(length(stock.Close),1);
    if(timeGap>=180)
       factor = (timeGap*0.075)/2;
    else
        factor = 10;
    end
    means = zeros(round(factor),1);
    for var=1:length(stock.Close)-round(1/2*timeGap)
        for var2=1:round(factor)
            means(var2) = stock.Close(randi(length(stock.Close)));   
        end
        temp(var) = mean(means);       
    end

    temp = temp + (stock.Close(end,1) - temp(1,1));
    if(timeGap>=180)
        for i=1:length(temp)
            if(mod(i,3) == 0)
                temp(i+1) = temp(i);
                temp(i+2) = temp(i);
            end
            if(i+3 > length(temp))
                break;
            end
        end
    end
    display = timeseries(stock.Close(:,1), datestr(stock(:,1).Date));
    display.Name = ('$USD');
    plot(display);
    hold on;
    dates = datetime(enddate) + days(0:round(timeGap*0.1) - 1);
    display = timeseries(temp(1:round(timeGap*0.1),1),datestr(dates));
    plot(display);
    hold off;
    title(upper(symbol));
    xlabel('Date');
    ylabel('Price');
    legend({'Real', 'Prediction'},'location','northwest');
    
end