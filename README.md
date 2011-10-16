# DataMapper SQL Finders

DataMapper SQL Finders adds `#by_sql` to your models, as a compliment to the standard pure-ruby
query system used by DataMapper.  The SQL you write will be executed directly against the adapter,
but you do not need to lose the benefit of the field and table name abstraction offered by DM.
When you invoke `#by_sql`, one or more table representations are yielded into a block, which you
provide.  These objects are interpolated into your SQL, such that you use DataMapper properties in
the SQL and make no direct reference to the real field names in the database schema.

I wrote this gem because my original reason for using DataMapper was that I needed to work with a
large, existing database schema belonging to an old PHP application, subsequently ported to Rails.
We need the naming abstraction offered by DataMapper, but we also prefer its design. That said, we
run some queries that are less than trivial, mixing LEFT JOINs and inline derived tables…
something which DataMapper does not currently handle at all.  `#by_sql` allows us to drop down to
SQL in places where we need it, but where we don't want to by-pass DataMapper entirely.

The `#by_sql` method returns a DataMapper `Collection` wrapping a `Query`, in just the same way
`#all` does.  Just like using `#all`, no SQL is executed until a kicker triggers its execution
(e.g. beginning to iterate over a Collection).

Because the implementation is based around a real DataMapper Query object, you can chain other
DataMapper methods, such as `#all`, or methods or relationships defined on your Model.

It looks like this:

``` ruby
class Post
  include DataMapper::Resource

  property :id,    Serial
  property :title, String

  belongs_to :user
end

class User
  include DataMapper::Resource

  property :id,       Serial
  property :username, String

  has n, :posts


  def self.never_posted
    by_sql(Post) { |u, p| "SELECT #{u.*} FROM #{u} LEFT JOIN #{p} ON #{p.user_id} = #{u.id} WHERE #{p.id} IS NULL" }
  end
end

User.never_posted.each do |user|
  puts "#{user.username} has never created a Post"
end
```

The first block argument is always the current Model.  You can optionally pass additional models to `#by_sql` and have
them yielded into the block if you need to join.

You may chain regular DataMapper finders onto the result (the original SQL is modified with the additions):

``` ruby
User.never_posted.all(:username.like => "%bob%")
```

## A note about DataMapper 2.0

The DataMapper guys are hard at work creating DataMapper 2.0, which involves a lot of under-the-surface changes, most
notably building DM's query interface atop [Veritas](https://github.com/dkubb/veritas), with the adapter layer generating
SQL by walking a Veritas relation (an AST - abstract syntax tree).  Because of the way DM 1 handles queries, it is not
trivial to support SQL provided by the user (except for the trival case of it being in the WHERE clause).  With any hope,
gems like this will either not be needed in DM 2.0, or at least will be easy to implement cleanly.

## Installation

Via rubygems:

    gem install dm-sql-finders

Note that while the gem is functional, it has several known limitations, which I aim to work about by improving the
parsing and generating logic.  It is unlikely you will hit the limitations unless you extensively use `#by_sql` in
conjunction with options such as `:links`.

## Detailed Usage

Note that in the following examples, you are not forced to use the table representations yielded into the block, but you
are encouraged to.  They respond to the following methods:

  - `tbl.*`: expands the splat to only the known fields defined in your model. Other fields in the database are excluded.
  - `tbl.to_s`: represents the name of the table in the database.  `#to_s` is invoked implcitly in String context. Note
     that if you join to the same table multiple times, DataMapper SQL Finders will alias them accordingly.
  - `tbl.property_name`: represents the field name in the database mapping to `property_name` in your model.

Writing the field/table names directly, while it will work, is not advised, since it will significantly hamper any future
efforts to chain onto the query (and it reads just like SQL, right?).

### Basic SELECT statements

Returning a String from the block executes the SQL when a kicker is invoked (e.g. iterating the Collection).

``` ruby
def self.basically_everything
  by_sql { |m| "SELECT #{m.*} FROM #{m}" }
end
```

### Passing in variables

The block may return an Array, with the first element as the SQL and the following elements as the bind values.

``` ruby
def self.created_after(time)
  by_sql { |m| ["SELECT #{m.*} FROM #{m} WHERE #{m.created_at} > ?", time] }
end
```

### Ordering

DataMapper always adds an ORDER BY to your queries if you don't specify one.  DataMapper SQL Finders behaves no differently.
The default ordering is always ascending by primary key.  You can override it in the SQL:

``` ruby
def self.backwards
  by_sql { |m| "SELECT #{m.*} FROM #{m} ORDER BY #{m.id} DESC" }
end
```

Or you can provide it as a regular option to `#by_sql`, just like you can with `#all`:

``` ruby
def self.backwards
  by_sql(:order => [:id.desc]) { |m| "SELECT #{m.*} FROM #{m}" }
end
```

Note that the `:order` option take precendence over anything specified in the SQL.  This allows method chains to override it.

### Joins

The additional models are passed to `#by_sql`, then you use them to construct the join.

``` ruby
class User
  ... snip ...

  def self.posted_today
    by_sql(Post) { |u, p| ["SELECT #{u.*} FROM #{u} INNER JOIN #{p} ON #{p.user_id} = #{u.id} WHERE #{p.created_at} > ?", Date.today - 1] }
  end
end
```

The `:links` option will also be interpreted and added to the `FROM` clause in the SQL.  This is useful if you need to override the SQL.

### Limits and offsets

These can be specified in the SQL:

``` ruby
def self.penultimate_five
  by_sql { |m| "SELECT #{m.*} FROM #{m} ORDER BY #{m.id} DESC LIMIT 5 OFFSET 5" }
end
```

Order they can be provided as options to `#by_sql`:

``` ruby
def self.penultimate_five
  by_sql(:limit => 5, :offset => 5) { |m| "SELECT #{m.*} FROM #{m}" }
end
```

If `:limit` and/or `:offset` are passed to `#by_sql`, they take precedence over anything written in the SQL itself.

### Method chaining

Method chaining with `#by_sql`, for the most part, works just like with `#all`.  There are some current limitations,
such as overriding `:links` (i.e. changing the JOIN condition in the SQL) and reversing the order of a query that
used `ORDER BY` in the SQL, rather than via an `:order` option.

Also note the you may not currently chain `#by_sql` calls together.  `#by_sql` must, logically, always be the first
call in the chain.

``` ruby
User.by_sql{ |u| ["SELECT #{u.*} FROM #{u} WHERE #{u.role} = ?", "Manager"] }.all(:username.like => "%bob%", :order => [:username.desc])
```

### Unions, Intersections and Differences

Unfortunately this is not currently supported, and will likely only be added after the other limitations are worked out.

Specifically, queries like this:

``` ruby
User.by_sql { |u| ["SELECT #{u.*} FROM #{u} WHERE #{u.created_at} < ?", Date.today - 365] } | User.all(:admin => true)
```

Should really produce SQL of the nature:

``` sql
SELECT "users"."id", "users"."username", "users"."admin" FROM "users" WHERE ("created_at" < ?) OR (admin = TRUE)
```

I have no idea what will happen if it is attempted, but it almost certainly will not work ;)

## Will it interfere with DataMapper?

Almost all of the implementation is unintrusive, but unfortunately, because DataMapper's DataObjects Adapter does not provide
a great deal of flexibility when it comes to SQL generation, the entire `#select_statement` method has been overridden.  For
non-`#by_sql` queries everything follows the original code pathways, and during a `#by_sql` query, the SQL is re-built using
a combination of the original logic and some custom logic to include your SQL.  In short, yes, it does interfere, but I don't
believe there are any alternatives without extensive work on DataMapper's Query interface and the DataObjects adapter itself.

DataMapper 2.0 *should* fix this.

## Contributors

DataMapper SQL Finders is currently written by Chris Corbyn, but I'm extremely open to contributors which can make the
extension feel as natural and robust as possible.  It should be developed such that other DataMapper gems (such as
dm-aggregates and dm-pager) still function without caring that raw SQL is being used in the queries.

## TODO

  - Support overriding `:fields` in a `#by_sql` query (complex if the query depends on RDBMS native functions)
  - Handle `:links` chained onto a `#by_sql` query
  - Reverse the order when invoking `#reverse` in a `#by_sql` query that used `ORDER BY` in the SQL (note this will work just fine if
    you use the `:order` option)
  - Better support for `?` replacements in places other than the `WHERE` clause
  - Support set operations (union, intersection, difference)

## Future Plans

Before I started writing this, I wanted to implement something similar to Doctrine's (PHP) DQL, probably called DMQL.
This is basically a strict superset of SQL that is pre-processed with DataMapper, having knowledge of your schema,
therefore allowing you to simplify the query and let DMQL hande things like JOIN logic.  Say, for example:

``` ruby
Post.by_dmql("JOIN User u WHERE u.username = ?", "Bob")
```

Which would INNER JOIN posts with users and map u.username with the real field name of the `User#username` property.

This gem would be a pre-requisite for that.

Copyright (c) 2011 Chris Corbyn.
