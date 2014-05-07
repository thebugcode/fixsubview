This fixes the issue Can't add self as subview which appeared on iOS 7.


In order to install, just make sure to add this category in your project. This category intercepts method calls using swizzling and overrides their behaviour to make pushing and poping self.
If you want to test that it works, try inserting breakpoints in the safePushViewController or others to see that it really is used.
