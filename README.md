This fixes the issue Can't add self as subview which appeared on iOS 7.


In order to install, just make sure to add this category in your project. This category intercepts method calls using swizzling and overrides their behaviour to make pushing and poping self.
If you want to test that it works, try inserting breakpoints in the safePushViewController or others to see that it really is used.

```Swift
if let
    path     = NSBundle.mainBundle().pathForResource("users", ofType: "json"),
    url      = NSURL(fileURLWithPath: path),
    data     = NSData(contentsOfURL: url),
    userList = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [[String: AnyObject]] 
{
    // extract individual users
    for userDict in userList {
        if let
            id      = userDict["id"] as? Int,
            name    = userDict["name"] as? String,
            email   = userDict["email"] as? String,
            address = userDict["address"] as? [String: AnyObject]
        {
            users.append(User(id: id, name: name, ...))
        }
    }
}
```
