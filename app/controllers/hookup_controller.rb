require 'http'
require 'google/api_client'

#GoogleCalendarのAOuth認証
class HookupController < ApplicationController
  
  # この↓一文がないとCSRF(Cross-Site Request Forgery)チェックでこけるので、APIをやりとりしているControllerには必要
  skip_before_filter :verify_authenticity_token
  
  #クライアントID,クライアントシークレット,承認済みのリダイレクトURI,カレンダーIDを入力
  def setup
  end
  
  #上記変数を受取る
  def getcode
    #@@clientId = params[:clientId]
    @@clientId = "841258018012-jqn06q4ifmfvbj5ip42rvtemetcga7oj.apps.googleusercontent.com"
    #@@clientId = "404180661728-qotv9so92qt4pp6s7v9jlmheik6bespe.apps.googleusercontent.com"
    #@@clientSecret = params[:clientSecret]
    @@clientSecret = "HuQ43i5_NiqOeOIZca4oJttJ"
    #@@clientSecret = "_ZS6_pVing3DInTzpJ7c3QpJ"
    #@@calendarId = params[:calendarId]
    @@calendarId = "i8a77r26f9pu967g3pqpubv0ng@group.calendar.google.com"
    #@@calendarId = "g8ukpibvlfle41hplt1g3rplu0@group.calendar.google.com"
    #@@redirectUri = params[:redirectUri]
    @@redirectUri = "https://google-demo-yumikotsunai.c9users.io/hookup/callback"
    #@@redirectUri = "https://kkeapidemo2.herokuapp.com/hookup/callback"
    
    #google認証のURLにリダイレクト
    url = 'https://accounts.google.com/o/oauth2/auth?client_id=' + @@clientId + '&redirect_uri=' + @@redirectUri + 
    '&scope=https://www.googleapis.com/auth/calendar&response_type=code&approval_prompt=force&access_type=offline'
    
    redirect_to(url)
  end
  
  
  #google認証後のリダイレクト先URI
  def callback
    #引数(=コード)を取得
    code = params[:code]
    #puts(@@clientId)
    #puts(@@clientSecret)
    #puts(@@redirectUri)
    
    #クライアントID,クライアントシークレット,承認済みのリダイレクトURI,コードから、リフレッシュトークンとアクセストークンを取得
    postbody = {
      :client_id => @@clientId,
      :client_secret => @@clientSecret,
      :redirect_uri => @@redirectUri,
      :grant_type => "authorization_code",
      :code => code
    }
    
    #HTTP.post(URL)でURLにpostリクエストを送る
    res = HTTP.headers("Content-Type" => "application/x-www-form-urlencoded").post("https://accounts.google.com/o/oauth2/token", :form => postbody )
	  #puts(res)
	  
	  res_json = JSON.parse res
	  #puts(res_json)
	  @@accessToken = res_json["access_token"]
	  @@refreshToken = res_json["refresh_token"]
	  #puts(@@accessToken)
	  #puts(@@refreshToken)
	  
	  createchannel
	  
	  render action: 'createchannel'
	  
  end
  
  
  #アクセストークンを利用してチャネルを作成
  def createchannel
    
    #(方法1)HTTPにPOSTリクエストを送る⇒こちらはCh
    #必要なのがhttpsなのでSSLを有効にする。とりあえず証明書は無視。
    #ctx      = OpenSSL::SSL::SSLContext.new
    #ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
    #HTTPにPOSTリクエストを送る
    #postbody = {
    #  "id": SecureRandom.uuid(),
	  #  "type": "web_hook",
	  #  "address": "https://google-demo-yumikotsunai.c9users.io/notifications/callback"
    #}
    #puts(postbody)
    
    ##HTTP.post(URL)でURLにpostリクエストを送る
    #auth = "Bearer " + @@accessToken
    #res = HTTP.headers("Content-Type" => "application/json",:Authorization => auth).post("https://www.googleapis.com/calendar/v3/calendars/yumikokke@gmail.com/events/watch", :ssl_context => ctx , :body => postbody.to_json)
	  
	  #(方法2)GoogleApiを利用する
	  client = Google::APIClient.new

    client.authorization.client_id = @@clientId
    client.authorization.client_secret = @@clientSecret
    client.authorization.refresh_token = @@refreshToken
    client.authorization.fetch_access_token!
    
    service = client.discovered_api('calendar', 'v3')
    
    res = client.execute!(
      api_method: service.events.watch,
      parameters: { calendarId: @@calendarId },
      body_object: {
        id: SecureRandom.uuid(),
        type: 'web_hook',
        #ローカル環境
        address: 'https://google-demo-yumikotsunai.c9users.io/notifications/callback'
        #heroku環境
        #address: 'https://kkeapidemo2.herokuapp.com/notifications/callback'
      }
    )
	  
	  @status = res.status
	  
	  if res.status.to_s == "200"
      @status = "認証に成功しました"
    else
	  	@status = "認証に失敗しました"
	  end
	  
	  puts(res.body)
	  
  end
  
  
  #クラス変数用メソッド
  def dispClientId
    return @@clientId
  end
  
  def dispClientSecret
    return @@clientSecret
  end
  
  def dispRedirectUri
    return @@redirectUri
  end
  
  def dispCalendarId
    return @@calendarId
  end
  
  def dispAccessToken
    return @@accessToken
  end
  
  def dispRefreshToken
    return @@refreshToken
  end
  
  
  
end
