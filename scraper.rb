# This program scrapes the Gymboree.com website and saves the data in a Sqlite3 database named scraper.db

require 'rubygems'
require 'mechanize'
require 'model/init'

@start_time = Time.now
@agent = WWW::Mechanize.new
@send_email_created = false
@send_email_deleted = false
@count = 0

### STEP 1: record the current time as a snapshot
@snapshot = Snapshot.create(:time => Time.now.to_i)

### STEP 2: Navigate the website and insert or update records on the "products_sizes" table
Department.each do |department|
  puts "Capturing department: " + department.name.upcase
  department_page = @agent.get(department.url)
  # start clicking through all the collections
  department_page.search("//div[@id='cat_0_show']/ul/li/a").each do |collection_link|
    unless (collection_link.text == 'Sale') # don't scrape the collection called 'Sale'
      # go back to the main department page before clicking each link because clicking collection links changes the menu
      department_page = @agent.get(department.url)
      collection_page = @agent.click collection_link
      puts "\tCapturing collection: " + collection_link.text
      collection = Collection.find_or_create(:department_id => department.id, :name => collection_link.text)
      collection.url = collection_link['href']

      # click the "view all" link if it exists
      collection_page.search("//div[@class='pagelinks_cat']/a").each do |page_link|
        if (page_link.text[0,8] == "view all")
          puts "\t...clicking on View All link"
          collection_page = @agent.click page_link
          break
        end
      end
      
      # start clicking through to all the products
      collection_page.search("//div[@class='products_cat']/table/tr/td/table/tr/td[2]/a").each do |product_link|
        @count += 1
        product_page = @agent.click product_link
        puts "\t\tCapturing product: " + product_link.text

        # scrape the page and store it via the model objects
        product = Product.find_or_create(:name => product_link.text, :collection_id => collection.id)
        product.url = product_link['href']
        select = product_page.search(".//select[@name='ADD_CART_ITEM<>sku_id']").first
        if select
          select.children.each do |opt|
            unless (opt.text == 'Select a Size') # don't scrape the dropdown's default text
              size = Size.find_or_create(:name => opt.text)
              product_size = ProductSize.find_or_create(:product_id => product.id, :size_id => size.id)
              if (product_size.created_sid == nil)
                product_size.set(:created_sid => @snapshot.id)
                @send_email_created = true
              end
              product_size.set(:updated_sid => @snapshot.id)
            end
          end
        end
      end
    end
  end
end

### STEP 3: For each product_size that is not new or udpated, mark it as deleted
ProductSize.where("updated_sid != #{@snapshot.id} AND (deleted_sid is null OR deleted_sid < updated_sid)").each do |d|
  d.set(:deleted_sid => @snapshot.id)
  @send_email_deleted = true
end

### STEP 4: Send an alert email if anything was created or deleted
if (false)
#if (@send_email_created)
#if (@send_email_created || @send_email_deleted)
  if (!@send_email_deleted)
    subject = "Something was INTRODUCED to Gymboree.com in the last hour"
  elsif (!@send_email_created)
    subject = "Something was REMOVED from Gymboree.com in the last hour"
  else
    subject = "There were things INTRODUCED and REMOVED from Gymboree.com in the last hour"
  end
  system "echo 'Go to http://trungly.com:7000 to check it out!' | mailx -s '#{subject}' trungly@gmail.com"
end

puts "Done with snapshot #{@snapshot.id} @ #{@snapshot.formatted_time}"
puts "Scraped #{@count} products in #{Time.now - @start_time} seconds"
