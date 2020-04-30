# whereAmI
![Logo](/whereAmI?/appstore.png)
Swift application which calculates the current user location, and using a TTS synthesizer, reads out loud locations near the user. The client makes HTTP requests to get other locations from the integrated API built in NodeJS and Express (in local).
The API is uploaded to Firebase so it can be accessed by everyone, through either requests or through the website below.

![in-App](/IMG_0203.PNG)


# Frontend :
- [Swift (UIKit)]
- [HTML5]
- [CSS]
- [JS]

# Backend :
* [NodeJS]
* [Express]
* [Firebase]

## Also used :
* SwiftyJSON
* FontAwesome_swift
* Alamofire

## API  :
> https://us-central1-whereami-275517.cloudfunctions.net/app
### Accepted calls :
- GET (to get the list of all locations in the Firebase DB)
- POST (with the location data as params)
- / (just to check the connection)

## The location input website can be found at :
> https://whereami-275517.web.app



Cheers !
