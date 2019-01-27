function getdata = getMarketDataViaYahoo(symbol, begin, ending)
    begin = posixtime(datetime(begin));
    ending = posixtime(datetime(ending)); 
    uri = matlab.net.URI(['https://finance.yahoo.com/quote/', upper(symbol), '/history'],...
        'period1',  num2str(uint64(posixtime(datetime())), '%.10g'),'period2',  num2str(uint64(posixtime(datetime())), '%.10g'),...
        'interval', '1d','filter', 'history','frequency', '1d','guccounter', 1);
    options = matlab.net.http.HTTPOptions('ConnectTimeout', 20, 'DecodeResponse', 1, 'Authenticate', 0, 'ConvertResponse', 0);
    crumb = "\";
    while(contains(crumb, '\'))
        requestObj = matlab.net.http.RequestMessage();
        [response, ~, ~]  = requestObj.send(uri, options);
        ind = regexp(response.Body.Data, '"CrumbStore":{"crumb":"(.*?)"}');
        if(isempty(ind))
            error([symbol ,' is not found']);
        end
        crumb = response.Body.Data.extractBetween(ind(1)+23, ind(1)+33);
    end
    setCookieFields = response.getFields('Set-Cookie');
    setContentFields = response.getFields('Content-Type');
    if ~isempty(setCookieFields)
       cookieInfos = setCookieFields.convert(uri);
       contentInfos = setContentFields.convert();
       requestObj = requestObj.addFields(matlab.net.http.field.CookieField([cookieInfos.Cookie]));
       requestObj = requestObj.addFields(matlab.net.http.field.ContentTypeField(contentInfos));
       requestObj = requestObj.addFields(matlab.net.http.field.GenericField('User-Agent', 'Mozilla/5.0'));
    else
        disp('Ticker Not Found');
        getdata = [];
        return;
    end
    uri = matlab.net.URI(['https://query1.finance.yahoo.com/v7/finance/download/', upper(symbol) ],...
        'period1',  num2str(uint64(begin), '%.10g'),...
        'period2',  num2str(uint64(ending), '%.10g'),...
        'interval', '1d',...
        'events',   'history',...
        'crumb',    crumb,...
        'literal');  
    options = matlab.net.http.HTTPOptions('ConnectTimeout', 20,...
        'DecodeResponse', 1, 'Authenticate', 0, 'ConvertResponse', 0);
    [response, ~, ~]  = requestObj.send(uri, options);
    if(strcmp(response, 'NotFound'))
        disp('No data available');
        getdata = [];
    else
        getdata = formTable(response.Body.Data);
    end
end
function procData = formTable(data)
    records = data.splitlines;
    header = records(1).split(',');
    content = zeros(size(records, 1) - 2, size(header, 1) - 1);
    for k = 1:size(records, 1) - 2
        items = records(k + 1).split(',');
        dates(k) = datetime(items(1));
        for l = 2:size(header, 1)
            content(k, l - 1) = str2double(items(l));
        end
    end
    finder = find(sum(isnan(content), 2) == 6);
    content(finder, :) = [];
    dates(finder) = [];    
	procData = table(dates', content(:,1), content(:,2),... 
            content(:,3), content(:,4), content(:,5),...
            content(:,6));
    for k = 1:size(header, 1)    
         procData.Properties.VariableNames{k} = char(header(k).replace(' ', ''));  
    end
end
