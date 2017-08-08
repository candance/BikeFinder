#Motivate iOS Coding Project

Create a simple mobile app to help new dispatchers find bike-share stations. The bike share provides [GBFS](https://github.com/NABSA/gbfs) feeds with all the information you need. The app should target the iOS 9.0 SDK.

##The Task
- Use the CitiBike API endpoints listed in the [GBFS](https://github.com/NABSA/gbfs/blob/master/systems.csv) repo.
- Using a mapping library of your choice, visually present information dispatchers may want to see. This includes, but is not limited to, location of stations, number of bikes and docks available, and whether or not the station is operating normally.
- Store the data locally so that it is accessible on load and in an offline state.
- Present the data on the map view. Add additional views as necessary.
- Write functional and integration tests to ensure the application behaves as expected. You may also wish to include UI tests if your app idncludes complex UI manipulation.

##Things to consider
- Each GBFS feed contains information that changes at varying intervals (see ttl). Data should always be up to date, but the spec is designed in a way that every feed should not have to be constantly polled.
- The apps should follow design patterns that are familiar to the platform. Refer to the Human Interface Guidelines (iOS, Android) if you need a refresher.
- Think about how stale data should be displayed—what happens if the user loses his or her connection?

You have 2 weeks to complete this project. Commit your work to this repository.

This is not expected to be perfect or extremely polished. Be prepared to discuss your results, design decisions, and goals, as well as how you would extend your app in the future.
