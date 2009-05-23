require 'rubygems'
require 'sinatra'
load 'model/init.rb'

before do
  request.env['PATH_INFO'] = '/' if request.env['PATH_INFO'].empty?
  @latest = Snapshot.s1("select id,max(time) as time from snapshots")
end

get '/' do
  haml :index
end

get '/dept/:id' do
  @dept = Department[params[:id]]
  haml :dept
end

get '/coll/:id' do
  @coll = Collection[params[:id]]
  haml :coll
end

get '/style.css' do
  content_type 'text/css'
  sass :style
end

__END__
@@ layout
%html
  %link{:rel => 'stylesheet', :href=>'/gymboree/style.css', :type => 'text/css'}
  = yield
  %p#footer
    last update:
    = @latest.formatted_time
