# DataMapper SQL Finders

[NOTICE: This README is stub.  This gem is not actually finished.]

DataMapper SQL Finders adds `#by_sql` to your models, as a compliment to the standard pure-ruby
query system used by DataMapper.  The SQL you write will be executed directly against the adapter,
but you do not need to lose the benefit of the field and table name abstraction offered by DM.
When you invoke `#by_sql`, one or more table representations are yielded into a block, which you
provide.  These objects are interpolated into your SQL, such that you use DataMapper properties in
the SQL and make no direct reference to the real field names in the database schema.  This is in
stark contrast to ActiveRecord, which couples your Ruby code very closely to your database schema.

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

## Installation

As of now, the gem is under development (started 7th October 2011).  I anticipate a first release will be ready within
a week or so.  It is a very simple concept, adding some decorations to `Query` and `DataObjectsAdapter`, but there are
still some big problems to solve and lots of specs to write.

## Detailed Usage

Note that in the following examples, you are not forced to use the table representations yielded into the block, but you
are encouraged to.  They respond to the following methods:

  - `tbl.*`: expands the splat to only the known fields defined in your model. Other fields in the database are excluded.
  - `tbl.to_s`: represents the name of the table in the database.  `#to_s` is invoked implcitly in String context. Note
     that if you join to the same table multiple times, DataMapper SQL Finders will alias them accordingly (TODO).
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
  by_sql { |m| ["SELECT #{m.*} FROM #{m} WHERE #{m.created_at > ?}", time] }
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

Method chaining with `#by_sql` works just like with `#all`.  The only (current) exception is that the `#by_sql` call must be the first
in the chain (I'm not sure how it would look, semantically, if a `#by_sql` call was made anywhere but at the start).

``` ruby
User.by_sql{ |u| ["SELECT #{u.*} FROM #{u} WHERE #{u.role} = ?", "Manager"] }.all(:username.like => "%bob%", :order => [:username.desc])
```

## Contributors

DataMapper SQL Finders is currently written by Chris Corbyn, but I'm extremely open to contributors which can make the
extension feel as natural and robust as possible.  It should be developed such that other DataMapper gems (such as
dm-aggregates and dm-pager) still function without caring that raw SQL is being used in the queries.

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
