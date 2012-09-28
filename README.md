Autogrid
========
The autogrid gem makes it easy to create automatic grids for rails using [Flexigrid](http://flexigrid.info/).

**CURRENTLY UNDER DEVELOPMENT - WILL NOT WORK - DO NOT USE**


## Usage
You will want to include any JS and CSS files in your header:

	<%= stylesheet_link_tag "autogrid/autogrid" %>
	<%= javascript_include_tag "autogrid/autogrid" %>

In your controller, you will want to do:

	class UsersController < ApplicationController
		def index
			@users = User.join(:role)
			# Or if using the Kaminari gem
			@users = User.page(params[:page]).per(params[:page])
			
			# Create the gem
			@grid = autogrid(@users, :default_sort => :last_name) do |g|
				# Columns displayed by default
				g.cols :last_name, :first_name
				
				# You can use associations as such:
				g.cols "role.name"
				
				# Columns that will be hidden by default, but may be unhidden
				g.cols :email, :hidden => true
			end
			
			respond_to do |format|
				format.html
				# Optionally render to CSV
				format.csv { render :csv => @grid.to_csv }
			end
		end
		
In your viewfile:

	<%= autogrid_render(@grid) %>

## Installation
This has only been tested to work in Rails - it is unlikely that this will work in anything else.

To use, add in your Gemfile:

	gem 'autogrid'

And that's it!

### Requirements
This gem is only compatible with Rails. It has only been tested using Rails 3.2.8, but it should work on earlier versions.

Autogrid requires the [jQuery](http://jquery.com/) and the [jQuery UI](http://jqueryui.com/) libraries for JavaScript functionality.

## Acknowledgments
This code was made open source by [FlexWage Solutions](http://www.flexwage.com/).