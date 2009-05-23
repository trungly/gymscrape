=begin
/* Mysql schema */
DROP TABLE departments;DROP TABLE collections;DROP TABLE products;DROP TABLE products_sizes;DROP TABLE sizes;DROP TABLE snapshots;
CREATE TABLE departments(id smallint primary key auto_increment, name varchar(64), url text);
CREATE TABLE collections(id integer primary key auto_increment, department_id integer, name varchar(64), url text);
CREATE TABLE products(id integer primary key auto_increment, collection_id integer, name varchar(64), url text);
CREATE TABLE products_sizes(id integer primary key auto_increment,product_id integer, size_id integer, created_sid integer, updated_sid integer, deleted_sid integer);
CREATE TABLE sizes(id integer primary key auto_increment, name varchar(64));
CREATE TABLE snapshots(id integer primary key auto_increment, time integer);
INSERT INTO departments (name,url) VALUES ('baby girl','http://www.gymboree.com/shop/asst_department.jsp?FOLDER%3C%3Efolder_id=2534374302774671');
INSERT INTO departments (name,url) VALUES ('kid girl','http://www.gymboree.com/shop/asst_department.jsp?FOLDER<>folder_id=2534374302774537');
=end
require 'dbi'
require 'm4dbi'
dbh = DBI.connect("DBI:Mysql:gymscrape", "trung")

class Snapshot < DBI::Model( :snapshots )
  def formatted_time
    Time.at(time.to_i).ctime
  end
end

class Product < DBI::Model( :products )
  def has_any_product_sizes?
    product_sizes.length > 0
  end
end

class Collection < DBI::Model( :collections ); end

class Department < DBI::Model( :departments ); end

class Size < DBI::Model( :sizes ); end

class ProductSize < DBI::Model( :products_sizes )
  def status
    case
      when !deleted_sid && (updated_sid == created_sid) then "created"
      when deleted_sid && deleted_sid > updated_sid then "deleted"
      when deleted_sid && deleted_sid < updated_sid then "restored"
      else "updated"
    end
  end
  def status_sid
    case status
      when "created" then created_sid
      when "deleted" then deleted_sid
      when "restored" then deleted_sid
      else updated_sid
    end
  end
  def html_styled_size_name
    case status
      when "created" then "<span style='font-weight: 600; color: green' title='Added around #{Snapshot[status_sid].formatted_time}'>#{size.name}</span>"
      when "deleted" then "<span style='font-weight: 600; color: red' title='Removed around #{Snapshot[status_sid].formatted_time}'>#{size.name}</span>"
      when "restored" then "<span style='font-weight: 600; color: #C0F' title='Originally removed around #{Snapshot[status_sid].formatted_time}'>#{size.name}</span>"
      else "<span>#{size.name}</span>"
    end
  end
end

DBI::Model.one_to_many( Department, Collection, :collections, :department, :department_id )
DBI::Model.one_to_many( Collection, Product, :products, :collection, :collection_id )
DBI::Model.one_to_many( Product, ProductSize, :product_sizes, :product, :product_id )
DBI::Model.one_to_many( Size, ProductSize, :product_sizes, :size, :size_id )

