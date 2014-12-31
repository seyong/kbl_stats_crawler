# encoding = utf-8

=begin
 Korean Basebal Statistic Crawler crawls baseball stats from naver sports and daum sports
=end

require 'rubygems'
require 'json'
require 'net/http'
require 'open-uri'
require 'nokogiri'


def saveAsJson(filename,jsondata)
	if !File.exist?(filename)
		File.open(filename,"w") do |f|
			f.write jsondata
			f.close
		end
	else
		f = File.new(filename,"w")
		f.write jsondata
		f.close
	end
end

def removeTbodyTag(doc)
	doc.xpath('//table/tbody').each do |tbody|
		tbody.children.each do |child|
			child.parent = tbody.parent
			end
		tbody.remove
	end
end


$urlhost = "sports.news.naver.com"
$urlpath = "/schedule/index.nhn?"

def geturl(year,month)
	params = URI.encode_www_form('category'=>"kbo","year"=>year.to_s,"month"=>month,"teamCode"=>"")
	url = "http://"+$urlhost+$urlpath+params
	url
end

#rqUrl = "http://sports.news.naver.com/schedule/index.nhn?category=kbo&year=2013&month=09&teamCode="

def getGameSchedule(year,month)
rqUrl = geturl(year,month)

doc = Nokogiri::HTML(open(rqUrl))
_data = doc.xpath('//div[@class="tb_wrap"]/div')
days = _data.to_a

# days = Nokogiri::NodeSet 
dayarr = Array.new
puts "day length: #{days.length}"
days.each_with_index do |day,i|
	#puts "#{i}"
	#_games = Hash.new
	_games = Array.new
	if day.values.first.strip.include?("nogame") then
		puts "nogame"
		# nogame
		#next
	else
		# there's been a game
		gamesaday = day.xpath('table/tbody/tr')
		#puts "gamesday length: #{gamesaday.length}"
		#date = game.xpath('td/span[@class="td_date"]/strong').text().strip
		strdate = ""
		gamesaday.each_with_index do |game,j|
		#	puts "#{j}"
			_game = Hash.new
			if !game.xpath('td/span[@class="td_stadium cancel"]').empty? then
			else
				if(strdate.empty?) then
					strdate = game.xpath('td/span[@class="td_date"]/strong').text().strip
				end
				_game[:date] = strdate 
				_game[:start_hour] = game.xpath('td/span[@class="td_hour"]').text().strip
				_game[:team_away] = game.xpath('td/span[@class="team_lft"]').text().strip
				_game[:team_home] = game.xpath('td/span[@class="team_rgt"]').text().strip
				_game[:urlpath] = game.xpath('td/span[@class="td_btn"]/a')[0].values.first
			end # game if end
			#_games["game#{j+1}"] = _game  # j must be 1-4
			_games.push(_game)
		#	puts "Done"
		end # gamesday block end
	end # if end
	#puts(_games)
	dayarr.push(_games)
end # each block end
return dayarr
end


$urlhost = "sports.news.naver.com"
$urlpath = "/schedule/index.nhn?"

month = Array.[]("03","04","05","06","07","08","09","10","11")
year = 2013


# ISSUE LIST
# 1.in each even month, data containes next odd month's first day data
# 	handling algorithm is required
# e.g. Apr. array contains 31 values, 31st vales is a data of May first!!
# 2. in each day data, only first tr has a :date value, the other tr does not have date value
#

month.each do |m|
	schedule_data = getGameSchedule(year,m)
	_hash = Hash.new
	_hash[:year] = year
	_hash[:month] = m
	_hash[:schedule] = schedule_data
	filename = "#{year}"+m+"_schedule.json"
	_json = _hash.to_json
	saveAsJson(filename,_json)
	puts "saved a schedule data!"
end


