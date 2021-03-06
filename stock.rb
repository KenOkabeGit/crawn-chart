#! ruby -EUTF-8
# -*- mode:ruby; coding:utf-8 -*-

require 'nokogiri'
require 'open-uri'
require 'erb'

#$SRC_HOME = "/home/kabuchk/crawl-chart"
$SRC_HOME = ENV['HOME']+"/src/crawl-chart"

$ERB_FILE = "#{$SRC_HOME}/index.html.erb"
$INDEX_FILE ="#{$SRC_HOME}/index.html"

class CompanyInfo
	def initialize
		@baseUrl = "http://stocks.finance.yahoo.co.jp/stocks"
	end

	def info(ticker_code)
		@tickerCode = ticker_code
		scrape
	end

	attr_reader :name, :tickerCode, :category,
		:unit, :recentHighPrice, :recentLowPrice,
		:highPrice, :lowPrice, :price, :lastDayPrice, :chartUrl

	private
	def get_company_info()
		url = "#{@baseUrl}/profile/?code=#{@tickerCode}"
		doc = get_nokogiri_doc(url)
		@name = doc.xpath("//th[@class='symbol']/h1").text
		@category = doc.xpath("//table[@class='boardFinCom marB6']/tr[6]/td").text
		@unit = doc.xpath("//table[@class='boardFinCom marB6']/tr[13]/td").text
	end

	def get_stock_info()
		url = "#{@baseUrl}/detail/?code=#{@tickerCode}"
		doc = get_nokogiri_doc(url)
		@recentHighPrice = doc.xpath("//div[11]/dl/dd[@class='ymuiEditLink mar0']/strong").text
		@recentLowPrice = doc.xpath("//div[12]/dl/dd[@class='ymuiEditLink mar0']/strong").text
		@highPrice = doc.xpath("//div[@class='innerDate']/div[3]/dl/dd[@class='ymuiEditLink mar0']/strong").text
		@lowPrice = doc.xpath("//div[@class='innerDate']/div[4]/dl/dd[@class='ymuiEditLink mar0']/strong").text
		@price = doc.xpath("//td[@class='stoksPrice']").text
		@lastDayPrice = doc.xpath("//*[@id='detail']/div[2]/div[1]/dl/dd/strong").text
		@chartUrl = "jpg/chart_#{@tickerCode}.jpg"
	end

	def get_chart()
		chartFile = "#{$SRC_HOME}/jpg/chart_#{@tickerCode}.jpg"
		img_url = "http://chart.yahoo.co.jp/?code=#{@tickerCode}.T&tm=6m&type=c&log=off&size=n&over=s,m75,m25&add=v&comp="
		open(chartFile, 'wb') do |file|
			open(img_url,'rb') do |data|
				file.write(data.read)
			end
		end
	end

	def get_chart_direct()
		url = "http://chart.yahoo.co.jp/?code=#{@tickerCode}.T&tm=6m&type=c&log=off&size=n&over=s,m75,m25&add=v&comp="
		print open(url,'rb').read
	end

	def get_nokogiri_doc(url)
		begin
			html = open(url)
		rescue OpenURI::HTTPError
			return
		end
		Nokogiri::HTML(html.read, nil, 'utf-8')
	end

	def scrape
		get_company_info
		get_stock_info
		get_chart
	end
end

class TickerCode
	def initialize
		@ticker = []
		for std_ticker in STDIN
			# p std_ticker.to_i
			@ticker.push(std_ticker.to_i)
		end
	end

		attr_reader :ticker
end

class HtmlOut
	def create_Html(harrayCompanyInfo)
    @harrayCompanyInfo = harrayCompanyInfo
    @content = get_HtmlCode($ERB_FILE)
    out_HtmlCode($INDEX_FILE)
	end


	private

	def get_HtmlCode(fileName)
    File.open(fileName,'r:utf-8'){|f|
      ERB.new(f.read).result(binding)
    }
  end

  def out_HtmlCode(fileName)
    File.open(fileName,'w:utf-8'){|f|
        f.write(@content)
    }
  end

	# get from ERB
	def get_chartName(arrayCompanyInfo)
    @arrayCompanyInfo = arrayCompanyInfo
    @name = arrayCompanyInfo[:name]
    @price = arrayCompanyInfo[:price]
    @strTickerCode = arrayCompanyInfo[:strTickerCode]
		@numTickerCode = arrayCompanyInfo[:numTickerCode]
		@highPrice = arrayCompanyInfo[:highPrice]
		@lowPrice = arrayCompanyInfo[:lowPrice]
		@recentHighPrice = arrayCompanyInfo[:recentHighPrice]
		@recentLowPrice = arrayCompanyInfo[:recentLowPrice]
		@lastDayPrice = arrayCompanyInfo[:lastDayPrice]
#		@fileName = "jpeg/chart_#{@numTickerCode}.jpg"
		@chartUrl = arrayCompanyInfo[:chartUrl]
	end
end



tickerCode = TickerCode.new
puts("取得銘柄数 ：" + tickerCode.ticker.size.to_s)
# p tickerCode.ticker

company = CompanyInfo.new
harrayCompanyInfo = []
tickerCode.ticker.each{|code|
	company.info(code)
	puts company.name
	puts company.category
	puts company.unit
	puts "年初来高値："+company.recentHighPrice
	puts "年初来安値："+company.recentLowPrice
	puts "高値："+company.highPrice
	puts "安値："+company.lowPrice
	puts "株価："+company.price
	puts "前日値:"+company.lastDayPrice
	puts "\n"


	harrayCompanyInfo.push({
		:numTickerCode => company.tickerCode,
		:strTickerCode => company.tickerCode.to_s,
		:name => company.name,
		:category => company.category,
		:unit => company.unit,
		:recentHighPrice => company.recentHighPrice,
		:recentLowPrice => company.recentLowPrice,
		:highPrice => company.highPrice,
		:lowPrice => company.lowPrice,
		:price => company.price,
		:lastDayPrice => company.lastDayPrice,
		:chartUrl => company.chartUrl
	})
}

HtmlOut.new.create_Html(harrayCompanyInfo)
