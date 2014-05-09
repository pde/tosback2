##ToSBack!##

This is a ruby implementation of TOSBack! Designed to scrape the Privacy Policies and Terms of Service agreements from sites defined in the rules folder. 

#### Rules

The log files in "logs" should give info on when the script was last run, and if one of the rule's URLs needs to be updated. Typically, tosback.rb will grab the body of a URL and try to strip away the html before storing the policy, but if a site is coming back as modified every time the script runs (thanks to ads or related links changing), you can now add an xpath attribute to the url in the xml data to pinpoint the TOS data on the page:

Here's an example:

	<docname name="Privacy Policy">
	  <url name="http://www.500px.com/privacy" xpath="//div[@id='terms']">
	   <norecurse name="arbitrary"/>
	  </url>
	</docname>

Now, tosback.rb should only grab the content we want from that URL! Hooray!

#### Developing

After cloning the project, use the `--without production` option to install the required gems:

  `$ bundle install --without production`

When the app runs without any options, it saves information to our database and automatically makes some new git commits, but this is probably only desirable in production. On your dev machine, run it like this to skip the db and auto-committing:

  `rubycode$ ruby main.rb -dev`

You can also pass a rule file as an argument to the script to get a preview of the results! For example:

  `rubycode$ ruby main.rb ../rules/abercrombie.com.xml`

This will only scrape and write the rule you pass, so you can add xpath data to a rule and quickly test to make sure it's correct.

Running with the "-empty" argument will scan the crawl directory and update the empty.log! Example:

  `rubycode$ ruby main.rb -empty`

