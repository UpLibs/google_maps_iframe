library google_maps_iframe;

import 'dart:html' ;
import 'dart:js' ;
import 'dart:async' ;

class GMapLatLong {

  double _latitude ;
  double _longitude ;
  
  GMapLatLong( num latitude , num longitude ) {
    this._latitude = latitude.toDouble() ;
    this._longitude = longitude.toDouble() ;
  }
  
  List<GMapLatLong> _group ;
  
  GMapLatLong.group( List<GMapLatLong> group ) {
    this._group = group ;
    setLatLongGroup(group) ;
  }
  
  double getWidth() {
    if (_group == null) return 0.0 ;
    
    double min = null ;
    double max = null ;
    
    for (var ll in _group) {
      if (min == null || min > ll.latitude) min = ll.latitude ;
      if (max == null || max < ll.latitude) max = ll.latitude ;
    }
    
    if ( min == null || max == null ) return 0.0 ;
    
    return max-min ;
  }
  
  double getHeight() {
    if (_group == null) return 0.0 ;
    
    double min = null ;
    double max = null ;
    
    for (var ll in _group) {
      if (min == null || min > ll.longitude) min = ll.longitude ;
      if (max == null || max < ll.longitude) max = ll.longitude ;
    }
    
    if ( min == null || max == null ) return 0.0 ;
    
    return max-min ;
  }
  
  double get latitude => _latitude ;
  double get longitude => _longitude ;
  
  void setLatLong(double latitude, double longitude) {
    this._latitude = latitude ;
    this._longitude = longitude ;
  }
  
  void setLatLongGroup( List<GMapLatLong> group ) {
    double minX = null ;
    double maxX = null ;

    double minY = null ;
    double maxY = null ;
    
    for (GMapLatLong ll in group) {
      
      if (minX == null || ll.latitude < minX ) minX = ll.latitude ;
      if (maxX == null || ll.latitude > maxX ) maxX = ll.latitude ;
      
      if (minY == null || ll.longitude < minY ) minY = ll.longitude ;
      if (maxY == null || ll.longitude > maxY ) maxY = ll.longitude ;
      
    }
    
    if ( minX == null || maxX == null ) {
      setLatLong(37.0625 , -95.677068) ;  
    }
    else {
      double centerX = minX + ((maxX - minX)/2) ;
      double centerY = minY + ((maxY - minY)/2) ;
      
      setLatLong(centerX, centerY) ;
    }
  }
  
  int getGroupMapZoom() {
    if (_group == null) return 2 ;
    
    double w = getWidth() ;
    double h = getHeight() ;
    
    double d = w > h ? w : h ;
    
    if (d <= 0.5) return 12 ;
    
    if (d <= 1) return 11 ;
    
    if (d <= 2) return 8 ;
    
    if (d <= 5) return 7 ;
    
    return 2 ;
  }
  
}


class GMapMarker {

  GMapLatLong _latLong ;
  
  String _name ;
  
  GMapMarker( this._latLong , this._name ) ;
  
  String get name => _name ;
  GMapLatLong get latLong => _latLong ;
  
}


class GMapIframe {
  
  
  //////////////////////////////////////////////////////
  
  jsEval_PARAMS(String code, List PARAMS) {
    /*
    print("<<<<<<");
    print(code) ;
    print(">>>>>>");
    */
    
    _inject_jsCall() ;
    
    JsObject obj = new JsObject.jsify(PARAMS) ;
    
    return context.callMethod('__UPPJSAPI__jsEval_PARAMS', [code , obj]) ;
  }
    
  Element get iframe => _iframe ;
  
  bool _inject_jsCall_Loaded = false ; 
    
  void _inject_jsCall() {
    
    if ( _inject_jsCall_Loaded ) return ;
    
    jsEval("""
      __UPPJSAPI__jsEval_PARAMS = function(CODE , PARAMS) {
          return eval(CODE) ;
      } ;
    
    """) ;
    
    _inject_jsCall_Loaded = true ;
    
  }
  
  jsEval(String code) {
    /*
    print("<<<<<<");
    print(code) ;
    print(">>>>>>");
    */
    
    return context.callMethod('eval', [code]) ;  
  }

  ///////////////////////////////////////////////////////////////
  
  static const int MAP_TYPE_ROADMAP = 0 ;
  static const int MAP_TYPE_SATELLITE = 1 ;
  static const int MAP_TYPE_HYBRID = 2 ;
  static const int MAP_TYPE_TERRAIN = 3 ;
  
  ///////////////////////////////////////////////////////////////

  static int _iframeIDCounter = 0 ;
  
  Element _iframe ;
  GMapLatLong _center ;
  int _zoom ;
  int _mapType ;
  
  GMapIframe(Element content, { num latitude: 0 , num longitude: 0 , int mapType: 0 , int zoom: 8 }) {
    
    this._center = new GMapLatLong( latitude , longitude ) ;
    this._mapType = mapType ;
    this._zoom = zoom ; 
    
    String id = '__GMapIframe_'+ (++_iframeIDCounter).toString() ;
    
    _iframe = new Element.iframe() ;
    _iframe.id = id ;
    _iframe.attributes['name'] = id ;
    _iframe.attributes['width'] = '100%' ;
    _iframe.attributes['height'] = '100%' ;
    _iframe.attributes['frameBorder'] = '0';
    
    content.children.add(_iframe) ;
    
    _iframe.onLoad.listen( (e) => new Future.microtask( _load ) ) ;
  }
  
  GMapLatLong get center => _center ;
  int get mapType => _mapType ;
  int get zoom => _zoom ;
  
  void setCenter( GMapLatLong latLong ) {
    this._center = latLong ;
    
    _callGMap_setCenter( latLong.latitude , latLong.longitude ) ;
  }
  
  void setMapType(int mapType) {
    _callGMap_setMapType(mapType) ;
  }
  
  void setZoom(int zoom) {
    _callGMap_setZoom(zoom) ;
  }
  
  void addMarker( GMapLatLong latLong , String title , bool dropAnimation ) {
    _callGMap_addMarker( latLong.latitude , latLong.longitude , title , dropAnimation ) ;
  }
  
  bool containsMarker( GMapLatLong latLong , String title ) {
    return _callGMap_containsMarker( latLong.latitude , latLong.longitude , title ) ;
  }
  
  bool removeMarker( GMapLatLong latLong , String title ) {
    return _callGMap_removeMarker( latLong.latitude , latLong.longitude , title ) ;
  }
  
  int getMarkersSize() {
    return _callGMap_getMarkersSize() ;
  }
  
  ////////////////////////////////////////////////////
  
  bool _gmapLoaded = false ;
  
  bool get isGMapLoaded => _gmapLoaded ; 
  
  void _onLoadGMap() {
    _gmapLoaded = true ;
    
    _jsGMapEvalFlush() ;
  }
  
  List<List> _evalCodes = [] ;
  
  void _jsGMapEvalFlush() {
    for (var eval in _evalCodes) {
      
      String code = eval[0] ;
      Function callBack = eval[1] ;
      
      var v ;
      
      if ( eval.length == 3 ) {
        List params = eval[2] ;
        v = jsEval_PARAMS(code, params) ;  
      }
      else {
        v = jsEval(code) ;
      }
      
      if (callBack != null) callBack(v) ;
    }
    
    _evalCodes = [] ;
  }
  
  void _jsGMapEval(String code , [callBack(value)] ) {
    if (_gmapLoaded) {
      var v = jsEval(code) ;
      if (callBack != null) callBack(v) ;
      return ;
    }
    
    _evalCodes.add([code, callBack]) ;
  }
  
  void _jsGMapEvalParams(String code, List params , [callBack(value)] ) {
    if (_gmapLoaded) {
      var v = jsEval_PARAMS(code, params) ;
      if (callBack != null) callBack(v) ;
      return ;
    }
    
    _evalCodes.add( [code , callBack , params] ) ;
  }
  
  //////////////////////////////////////////////////////
  
  void _callGMap_setCenter(double lat, double long) {
    _jsGMapEval("""{
         document.__GMapIframe__iframe_doc.gmap_setCenter($lat , $long) ;
      }""") ;
  }
  
  GMapLatLong _callGMap_getCenter() {
      if ( !_gmapLoaded ) return null ;
    
      JsObject obj = jsEval("""{
         document.__GMapIframe__iframe_doc.gmap_getCenter() ;
      }""") ;
      
      num lat = obj['lat'] ;
      num long = obj['lng'] ;
      
      return new GMapLatLong(lat, long) ;
  }
  
  void _callGMap_setMapType(int mapType) {
    _jsGMapEval("""{
         document.__GMapIframe__iframe_doc.gmap_setMapType($mapType) ;
    }""") ;
  }
  
  void _callGMap_setZoom(int zoom) {
    _jsGMapEval("""{
         document.__GMapIframe__iframe_doc.gmap_setZoom($zoom) ;
    }""") ;
  }
  
  void _callGMap_addMarker(double lat, double long, String title, bool dropAnimation) {
    _jsGMapEvalParams("""{
         document.__GMapIframe__iframe_doc.gmap_addMarker($lat,$long, PARAMS[0], ${ dropAnimation ? 1 : 0 }) ;
    }""" , [ title ]) ;
  }
  
  bool _callGMap_containsMarker(double lat, double long, String title) {
    var ok = jsEval_PARAMS("""{
         return document.__GMapIframe__iframe_doc.gmap_containsMarker($lat,$long, PARAMS[0]) ;
    }""" , [ title ]) ;
    
    return ok ;
  }
  
  bool _callGMap_removeMarker(double lat, double long, String title) {
    var ok = jsEval_PARAMS("""{
         return document.__GMapIframe__iframe_doc.gmap_removeMarker($lat,$long, PARAMS[0]) ;
    }""" , [ title ]) ;
    
    return ok ;
  }
  
  int _callGMap_getMarkersSize() {
    int size = jsEval("""{
         return document.__GMapIframe__iframe_doc.gmap_getMarkersSize() ;
    }""") ;
    
    return size ;
  }
  
  ////////////////////////////////////////////////////
  

  StreamController<GMapMarker> _controller_onMarkerClick = new StreamController<GMapMarker>() ;
  Stream<GMapMarker> get onMarkerClick => _controller_onMarkerClick.stream ;
  
  
  ////////////////////////////////////////////////////
  
  String get iframeID => _iframe.id ; 
  
  bool _loaded = false ;
  void _load() {
    if (_loaded) return ;
    _loaded = true ;
    _loadIFrameContent() ;
  }
  
  void _loadIFrameContent() {
    
    Function callBack_OnLoad = () {
      _onLoadGMap() ;
    };
    
    Function callBack_MarkerClick = (double lat, double long, String name) {
      _controller_onMarkerClick.add( new GMapMarker(new GMapLatLong(lat, long), name) ) ;
    };
    
    jsEval_PARAMS("""{
       var callBack_OnLoad = PARAMS[0] ;
       var callBack_MarkerClick = PARAMS[1] ;

       document.__GMapIframe__callBack_OnLoad = function() {
          callBack_OnLoad() ;
       };

       document.__GMapIframe__callBack_MarkerClick = function(lat, long, name) {
          callBack_MarkerClick(lat, long, name) ;
       };

       var myIframe = document.getElementById('$iframeID') ;
       var iFrameWindow = myIframe.contentWindow || myIframe.documentWindow ;
       var iFrameDoc = iFrameWindow.document ;

       document.__GMapIframe__iframe = myIframe ;
       document.__GMapIframe__iframe_win = iFrameWindow ;
       document.__GMapIframe__iframe_doc = iFrameDoc ;

       iFrameDoc.open() ;

       iFrameDoc.write("<html><head><style type='text/css'> html { height: 100% } body { height: 100%; margin: 0; padding: 0 } #map-canvas { height: 100% } </style><script type='text/javascript' src='https://maps.googleapis.com/maps/api/js?sensor=true'></script>${ _gmapControlJS() }</head><body onresize='resizeMapEvent()'><div id='map-canvas'/></div></body></html>") ;

       iFrameDoc.close() ;

    }""" , [callBack_OnLoad, callBack_MarkerClick]) ;
    
  }
  
  String _gmapControlJS() {
    String js = """

    <script type='text/javascript'>

      document.gmap_parentDoc = window.parent.document ; 
    
      document.gmap_getCenter = function() {
        return document.gmap.getCenter() ;
      } ;

      document.gmap_setCenter = function(lat,long) {
        document.gmap.setCenter( new google.maps.LatLng(lat,long) ) ;
      } ;

      document.gmap_setMapType = function(mapType) {
        document.gmap.setMapTypeId( mapTypeId(mapType) ) ;
      } ;

      document.gmap_getZoom = function(zoom) {
        document.gmap.getZoom() ;
      } ;

      document.gmap_setZoom = function(zoom) {
        document.gmap.setZoom(zoom) ;
      } ;

      var gmapMarkers = [] ;

      document.gmap_getMarkersSize = function() {
        return gmapMarkers.length ;
      } ;

      document.gmap_containsMarker = function(lat,long,title) {
        var m = document.gmap_getMarker(lat,long,title) ;
        return m != null ;
      } ;

      document.gmap_getMarker = function(lat,long,title) {
        for (var i = 0; i < markers.length; i++) {
          var m = markers[i] ;

          if ( m.getTitle == title ) {
            var p = m.getPosition() ;

            var pLat = p.lat() ;
            var pLng = p.lng() ;

            var diffLat = pLat - lat ;
            var diffLng = pLng - long ;

            if (diffLat < 0) diffLat = -diffLat ;
            if (diffLng < 0) diffLng = -diffLng ;

            if (diffLat < 0.0001 && diffLng < 0.0001) return m ;
          }
        }

        return null ;
      } ;

      document.gmap_removeMarker = function(lat,long,title) {
        var m = document.gmap_getMarker(lat,long,title) ;
        if ( m != null ) {
          m.setMap(null) ;
          return true ;
        }
        return false ;
      } ;

      document.gmap_addMarker = function(lat,long,title,dropAnim) {
        var marker = new google.maps.Marker({
          position: new google.maps.LatLng(lat,long) ,
          map: document.gmap ,
          animation: dropAnim ? google.maps.Animation.DROP : null ,
          title: title
        });

        gmapMarkers.push(marker) ;

        google.maps.event.addListener(marker, 'click', function() {
          var pos = marker.getPosition() ;
          document.gmap_parentDoc.__GMapIframe__callBack_MarkerClick( pos.lat() , pos.lng() , marker.getTitle() ) ;
        });
      } ;

      function mapTypeId(typeId) {
        if (typeId == 0) return google.maps.MapTypeId.ROADMAP ;
        if (typeId == 1) return google.maps.MapTypeId.SATELLITE ;
        if (typeId == 2) return google.maps.MapTypeId.HYBRID ;
        if (typeId == 3) return google.maps.MapTypeId.TERRAIN ;

        return google.maps.MapTypeId.ROADMAP ;
      }

      function initialize() {
        var mapOptions = {
          center: new google.maps.LatLng(${ _center.latitude }, ${ _center.longitude }) ,
          zoom: ${ _zoom } ,
          mapTypeId: mapTypeId( ${ _mapType } )
        };

        document.gmap = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

        document.gmap_parentDoc.__GMapIframe__callBack_OnLoad() ;
      }

      function resizeMapEvent() {
        google.maps.event.trigger(document.gmap , 'resize');
      }
      
      google.maps.event.addDomListener(window, 'load', initialize);

    </script>

    """;
    
    //print(js) ;
    
    js = js.replaceAll(new RegExp(r'[\r\n][ \t]+', multiLine: false), ' ') ;
    
    js = js.replaceAll(new RegExp(r'[\r\n]', multiLine: false), ' ') ;
    
    if (js.contains('"')) throw new StateError('can\'t have char " in the code') ;
    
    return js ;
  }
  
}