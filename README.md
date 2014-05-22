google_maps_iframe.dart
============

A wrapper for Google Maps JS API inside a iframe. Outside of an iframe the Google Maps component is not stable when working with CSS 3D transformations and animations. 


##Example

```dart

import 'dart:html';
import 'dart:async';

import 'package:google_maps_iframe/google_maps_iframe.dart';

main() {
  
  Element elem = new Element.div() ;
  elem.text = 'Google Map:';
  
  Element cont = querySelector('#cont') ;
  
  GMapIframe gmap = new GMapIframe(cont) ;
  
  new Future.delayed(new Duration(seconds: 3) , () {
    gmap.setCenter( new GMapLatLong(-27.5928287 , -48.5195031)) ;
    gmap.setZoom(12) ;
    
    gmap.addMarker( new GMapLatLong(-27.5928287 , -48.5195031) , 'Florianopolis' ) ;
  }) ;
  
  new Future.delayed(new Duration(seconds: 5) , () {
      gmap.setMapType(GMapIframe.MAP_TYPE_TERRAIN) ;
  }) ;
  
}


```

TODO
----

* More examples of usage.


CHANGELOG
---------

  * version: 0.1.1:
  Fix load of iframe code.

  * version: 0.1.0:
  First version

