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

You may chain regular DataMapper finders onto the result (the original SQL is modified with the additions):

``` ruby
Users.never_posted.all(:username.like => "%bob%")
```

## Installation

As of now, the gem is under development (started 7th October 2011).  I anticipate a first release will be ready within
a week or so.  It is a very simple concept, adding some decorations to `Query` and `DataObjectsAdapter`, but there are
still some big problems to solve and lots of specs to write.

## Contributors

DataMapper SQL Finders is currently written by Chris Corbyn, but I'm extremely open to contributors which can make the
extension feel as natural and robust as possible.  It should be developed such that other DataMapper gems (such as
dm-aggregates and dm-pager) still function without caring that raw SQL is being used in the queries.

## Future Plans

Before I started writing this, I wanted to implement something similar to Doctrine's (PHP) DQL, probably called DMQL.
This is basically a strict superset of SQL that is pre-processed with DataMapper, having knowledge of your schema,
therefore allowing you to simplify the query and let DMSQL hande things like JOIN logic.  Say, for example:

``` ruby
Post.by_dmql("JOIN User u WHERE u.username = ?", "Bob")
```

Which would INNER JOIN posts with users and map u.username with the real field name of the `User#username` property.

This gem would be a pre-requisite for that.

Copyright (c) 2011 Chris Corbyn.
