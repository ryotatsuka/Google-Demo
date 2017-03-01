include ConnectHttp
require 'net/https'
require 'http'
require 'time'
  
#ConnectのAOuth認証
class ConnecthookupController < ApplicationController
  
  #connect認証のURLにリダイレクト
  def new
    key = "demo@remotelock.com"
    #ローカル環境
    @@client =	"248b4559af5bbdf84998f5c092bc8d9fac784712f28009168c0a1579818aef47"
    @@secret =	"b88822e0976b6e6a9fb0096a3b1c860b12f9a405fd2d0597a1d60cf68473ac46"
    @@callbackuri = URI.encode('https://google-demo-yumikotsunai.c9users.io/connecthookup/callback')
    
    #heroku環境
    #@@client =	"86169dfc79da7ce9000a1d2f37dcb95f96d9b3bb03bf32e57b540cbaedbf0989"
    #@@secret =	"1bfa525b96c3102c65d1f2be4abfa541f0b57ee17ac92dffbb9abf6417740c23"
    #@@callbackuri = URI.encode('https://kkeapidemo2.herokuapp.com/connecthookup/callback')
    
    if Connectaccount.find_by(key: key) == nil
      account = Connectaccount.new(key: key,client_id: @@client,client_secret: @@secret)
      account.save
    end
    
    req = 'https://connect.lockstate.jp/oauth/'+'authorize?'+'client_id='+@@client+'&response_type=code&redirect_uri='+@@callbackuri
    redirect_to req
    
  end

  #トークンの受取り
  def callback
    #必要なのがhttpsなのでSSLを有効にする。とりあえず証明書は無視。
    #ctx = OpenSSL::SSL::SSLContext.new
    #ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    tmp_token = params[:code]
    postform = {'code' => tmp_token \
    ,'client_id' => @@client \
    ,'client_secret' => @@secret \
    ,'redirect_uri' => @@callbackuri\
    ,'grant_type' => 'authorization_code' }
    
    res = HTTP.headers("Content-Type" => "application/x-www-form-urlencoded")
    .post("https://connect.lockstate.jp/oauth/token", :ssl_context => CTX , :form => postform)
    
    if res.code!=200
      @res = res
      @state = "認証に失敗しました"
      render
    else
      @res = res
      j = ActiveSupport::JSON.decode( @res.body )
      #Connecttoken.find()
      #puts j
      require 'time'
      #require 'date'
      #Time.now.strftime("%Y年 %m月 %d日, %H:%M:%S")
      key = "demo@remotelock.com"
      data = { \
        :key => key \
        ,:access_token => j["access_token"] \
        ,:refresh_token => j["refresh_token"] \
        ,:expire => j["created_at"]+j["expires_in"]
      }
      #begin
      
      if Connecttoken.find_by(key: key) == nil
        connecttoken = Connecttoken.new(data)
        connecttoken.save
        puts "新しいものとして認識"
      else
        connecttoken = Connecttoken.find_by(:key => key)
        Connecttoken.update(connecttoken.id , :key => key,:access_token => j["access_token"] ,:refresh_token => j["refresh_token"] ,:expire => j["created_at"]+j["expires_in"],:updated_at => Time.now)
        puts "更新する"
      end
      #rescue
      #  puts "データベースへの保存で問題が発生しました"
      #end
      
      @res = connecttoken
      @state = "認証に成功しました"
      render
      
    end
    
  end
  
end
