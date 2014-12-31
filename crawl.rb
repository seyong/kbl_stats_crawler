# encoding = utf-8
#
# Created by Seyong Ha, 
#

# /GET
# Requested URL: http://sports.news.naver.com/gameCenter/gameResult.nhn?category=kbo&gameId=?
# Referer: http://sportsnews.naver.com/schedule/index.nhn?category=kbo
# Paramter
#		gameId = 3333MMDDT1T20

require 'rubygems'
require 'json'
require 'open-uri'
require 'net/http'
require 'nokogiri'

$hostUrl = "sports.news.naver.com"
$urlPath = "/gameCenter/gameResult.nhn?"


def getUrl(gameId)
	params = URI.encode_www_form('category'=>"kbo",'gameId'=>gameId)
	url = "http://"+$hostUrl+$urlPath+params
end

def getURL(path)
	url = "http://"+$hostUrl+path
	return url
end

def setRefererToHeaders(req)
	referer = "http://sports.news.naver.com/schedule/index.nhn?category=kbo"
	req['Referer'] = referer
	req
end

def getJSON(jsonstr)
	jsondata = JSON.parse(jsonstr)
	jsondata
end

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


def at_bat(rqUrl) 
# at bat information
rqUrl = rqUrl+"&teamCode="

doc = Nokogiri::HTML(open(rqUrl))
tmpstr = doc.xpath('//html/body/div[@id="wrap"]/script')[1].text()
tmpstr = tmpstr[/_data : (.*)/]
tmpstr.chop.chop
jsonstr = "{"+"\""+tmpstr[1..4]+"\""+tmpstr[5..-3]
json = JSON.parse(jsonstr+"}")
return json
end

def inning(rqUrl)
# inning information
#input url: "http://sports.news.naver.com/gameCenter/gameResult.nhn?category=kbo&gameId=YYYYMMDDT1T20"
#converted url: "http://sportsdata.naver.com/ndata//kbo/YYYY/MM/YYYYMMDDT1T2.nsd"
_gameinfo = rqUrl[-13..-1]
_yyyy = _gameinfo[0..3]
_mm = _gameinfo[4..5]
converted_url = "http://sportsdata.naver.com/ndata//kbo/"+_yyyy+"/"+_mm+"/"+_gameinfo+".nsd"

doc = Nokogiri::HTML(open(converted_url))
tmpstr = doc.xpath('//html/head/script').text()
jsonstr = tmpstr[/{(.*)/].chop().chop()
json = JSON.parse(jsonstr)
return json
end
###############
# 
# Main Procedure
#

# read jsondata from file


$foldername = "raw_data"
$atbat_folder = "at_bat"
$inning_folder = "inning"

folderpath = $foldername
#atbat_fd_path = "../"+$foldername+"/"+$atbat_folder
#inning_fd_path = "../"+$foldername+"/"+$inning_folder
atbat_fd_path = $foldername+"/"+$atbat_folder
inning_fd_path = $foldername+"/"+$inning_folder


schedules = Dir.entries("schedule/.")
#Dir.chdir("../schedule")

# folder check
if(!Dir.exists?(folderpath))	
	Dir.mkdir(folderpath)
end
if(!Dir.exists?(atbat_fd_path))
	Dir.mkdir(atbat_fd_path)
end
if(!Dir.exists?(inning_fd_path))
	Dir.mkdir(inning_fd_path)
end

#Dir.chdir(folderpath)

puts "start to crawl..."
schedules.each do |file|
	file = "schedule/"+file
	if(file.eql?("schedule/.") || file.eql?("schedule/..")) then
		next
	else
		puts(file)
		jsonfile= File.open(file,"r")
		jsondata = JSON.parse(IO.read(jsonfile)) #jsondata.class = Hash
		year = jsondata["year"] # Fixnum type
		month = jsondata["month"] # String type
		monthly_schedule = jsondata["schedule"] # Array
		atbat_fpath = atbat_fd_path+"/"+month
		inning_fpath = inning_fd_path+"/"+month

		if(!Dir.exists?(atbat_fpath))
			Dir.mkdir(atbat_fpath)
		end
		if(!Dir.exists?(inning_fpath))
			Dir.mkdir(inning_fpath)
		end

		monthly_schedule.each do |daily|
			if(!daily.empty?)	then
				daily.each do |game|
					if(!game.empty?) then
					print(game["urlpath"])
					url = getURL(game["urlpath"])
					begin
					atbat = at_bat(url)
					inning = inning(url)
					atbat_path = atbat_fpath+"/"+url[-13..-1]+"_atbat.json"
					inning_path = inning_fpath+"/"+url[-13..-1]+"_inning.json"
					saveAsJson(atbat_path,atbat.to_json)
					saveAsJson(inning_path,inning.to_json)
					puts("-End-")	
					rescue OpenURI::HTTPError => e
						puts "No page found: #{url} returned an error. #{e.message}. "
						next
					end
					end
				end #block end
			end #if end
		end # block end
	end # end if
end # end block


