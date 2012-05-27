class App < Sinatra::Base

  enable :sessions
  use Rack::Flash
  use Rack::CommonLogger

  $redis = Redis.new

  get '/?' do
    @tickers                                = get_tickers
    @tickers_with_counts                    = @tickers.collect { |symbol| [symbol, $redis.scard(symbol)] }
    @tickers_with_counts.sort! { |x,y| x[1] <=> y[1] }
    @top                                    = @tickers_with_counts[0..9].reverse

    @hits_keys = $redis.keys 'hits:*'
    @hits = []
    @hits_keys.each do |host_key|
      host = host_key.gsub("hits:", '')
      @hits << [host, $redis.get(host_key).to_i]
    end

    @hits = @hits.sort { |x, y| x[1] <=> y[1] }.reverse[0..9]
    erb :index
  end

  get '/tickers' do
    @tickers      = get_tickers
    @tickers_data = {}
    @tickers.each { |t| @tickers_data[t] = { :last_indexed => nil, :article_count => nil } }
    @tickers.each do |symbol| 
      @tickers_data[symbol][:article_count] = $redis.scard symbol
      time = $redis.get "indextime:#{symbol.upcase}"
      time = DateTime.strptime(time,'%s') if time
      @tickers_data[symbol][:last_indexed]  = time
    end

    erb :'tickers/index'
  end

  get '/tickers/:symbol' do
    @ticker = params[:symbol]
    @pages = $redis.smembers @ticker.upcase
    erb :'tickers/show'
  end

  get '/tickers/:symbol/reindex' do
    @ticker = params[:symbol].upcase
    queue_job @ticker
    set_timestamp @ticker
    flash[:success] = "Reindexing #{@ticker}"
    redirect '/tickers'
  end

  post '/tickers/clear' do
    @tickers = get_tickers
    @tickers.each { |t| $redis.del t }
    $redis.del 'tickers'
    flash[:success] = "Tickers data has been cleared"
    redirect '/tickers'
  end

  get '/queue' do
    @queue = get_queued_jobs
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
    @ticker = params[:symbol]
    if @ticker
      queue_job @ticker
      $redis.sadd('tickers', @ticker)
      flash[:success] = "Beginning index of #{@ticker}"
      redirect '/tickers'
    else
      flash[:error] = "Please provide a ticker to index"
      redirect '/tickers'
    end
  end

  post '/reindex' do
    @tickers = $redis.smembers('tickers')
    @tickers.each do |ticker| 
      queue_job ticker
      set_timestamp ticker
    end
    flash[:success] = "Beginning index of all tickers"
    redirect '/tickers'
  end

  post '/clear' do
    $redis.flushall
    flash[:success] = "Sources, Tickers, and Indexed data have been cleared"
    redirect '/'
  end

  private

  def queue_job(symbol)
    $redis.lpush('work', symbol)
  end

  def get_tickers
    $redis.smembers('tickers') || []
  end

  def get_queued_jobs
    $redis.lrange('work', 0, -1)
  end

  def set_timestamp(symbol)
    $redis.set("indextime:#{symbol}", Time.now.to_i);
  end
end