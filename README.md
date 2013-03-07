# FBStackableURLCache
This subclass of NSURLCache enables you to segregate your URLCache data into multiple separate caches.
You can chain these caches together as a set of request filters, or you can trivially implement your own custom datastore without having to fully implement NSURLCache subclasses.
Additionally, if you use the Provided NSURLCache+StackableURLCaching category, you no longer have to worry about someone's code in a library, unhooking your sharedURLCache for their own.

Example Applications:
- Making your own [upside-down-ternet/kittenwar](http://www.ex-parrot.com/pete/upside-down-ternet.html) browser for iPhone
- Dynamically querying different size images for each Facebook profile browsed, so you can proved a really snappy facebook app with zoomable images!
- Build a proxying webbrowser that speeds up mobile performance, just like [Amazon Silk](http://en.wikipedia.org/wiki/Amazon_Silk)
- Providing a child-safe webbrowser by blocking images that don't come from a set of whitelisted domains.

## Author: 
Frederic Barthelemy - github@fbartho.com

