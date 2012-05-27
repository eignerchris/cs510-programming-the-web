class App < Sinatra::Base

  enable :sessions
  use Rack::Flash
  use Rack::CommonLogger

  $redis = Redis.new

  get '/?' do
    @tickers                               = $redis.smembers('tickers') || []
    @tickers_with_counts                   = @tickers.collect { |symbol| [symbol, $redis.scard(symbol)] }
    @tickers_with_counts.sort! {|x,y| x[1] <=> y[1]}
    @top                                   = @tickers_with_counts[0..9].reverse
    erb :index
  end

  get '/tickers' do
    @tickers           = $redis.smembers('tickers') || []
    @tickers_data = {}
    @tickers.each { |t| @tickers_data[t] = {:last_indexed => nil, :article_count => nil }}
    @tickers.each do |symbol| 
      @tickers_data[symbol][:article_count] = $redis.scard symbol
      @tickers_data[symbol][:last_indexed]  = $redis.get "indextime:#{@ticker}"
    end

    erb :'tickers/index'
  end

  get '/tickers/:symbol' do
    @ticker = params[:symbol]
    @pages = $redis.smembers @ticker.upcase
    erb :'tickers/show'
  end

  get '/tickers/:symbol/reindex' do
    $redis.lpush('work', params[:symbol])
    $redis.set("indextime:#{@ticker}", DateTime.now);
    flash[:success] = "Reindexing #{params[:symbol]}"
    redirect '/tickers'
  end

  post '/tickers/clear' do
    @tickers = $redis.smembers 'tickers'
    @tickers.each { |t| $redis.del t }
    $redis.del 'tickers'
    flash[:success] = "Tickers data has been cleared"
    redirect '/tickers'
  end

  get '/queue' do
    @queue = $redis.lrange('work', 0, -1)
    erb :queue
  end

  post '/queue/clear' do
    $redis.del 'queue'
    flash[:success] = "Queue has been cleared"
    redirect '/queue'
  end

  get '/sources' do
    @sources = $redis.smembers('sources') || []
    erb :sources
  end

  post '/sources' do
    source = params[:url]
    $redis.sadd('sources', source)
    flash[:success] = "#{params[:url]} added to sources"
    redirect '/sources'
  end

  post '/sources/clear' do
    $redis.del 'sources'
    flash[:success] = "Sources have been cleared"
    redirect '/sources'
  end

  post '/index' do
    if params[:symbol]
      $redis.lpush('work', params[:symbol])
      $redis.sadd('tickers', params[:symbol].upcase)
      flash[:success] = "Beginning index of #{params[:symbol]}"
      redirect '/tickers'
    else
      flash[:error] = "Please provide a ticker to index"
      redirect '/tickers'
    end
  end

  post '/reindex' do
    @tickers = $redis.smembers('tickers')
    @tickers.each do |ticker| 
      $redis.lpush('work', ticker)
      $redis.set("indextime:#{ticker}", DateTime.now)
    end
    flash[:success] = "Beginning index of #{params[:symbol]}"
    redirect '/tickers'
  end

  post '/clear' do
    $redis.flushall
    flash[:success] = "Sources, Tickers, and Indexed data have been cleared"
    redirect '/'
  end
end