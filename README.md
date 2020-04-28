# whereAmI
Swift application which calculates the current user location, and using a TTS synthesizer, read out loud locations near the user. The client makes HTTP requests to get other locations from the integrated API build in NodeJS and Express. 

# Frontend :
- UIKit, Swift, HTML5, CSS

# Backend :
- NodeJS, Express, Firebase

Also used :
    + SwiftyJSON
    + FontAwesome_swift

The server is volatile at the moment, as it saves data per process (until server is closed). 
The project will be moved to Firebase so as the data persists, through Cloud Functions.
