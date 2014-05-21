library google_maps_iframe;

import 'dart:html' ;
import 'dart:js' ;

class GMapLatLong {

  double _latitude ;
  double _longitude ;
  
  GMapLatLong( num latitude , num longitude ) {
    this._latitude = latitude.toDouble() ;
    this._longitude = longitude.toDouble() ;
  }
  
  GMapLatLong.group( List<GMapLatLong> group ) {
    setLatLongGroup(group) ;
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

    double centerX = minX + ((maxX - minX)/2) ;
    double centerY = minY + ((maxY - minY)/2) ;
    
    setLatLong(centerX, centerY) ;
  }
  
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
    
    _load() ;
  }
  
  GMapLatLong get center => _center ;
  int get mapType => _mapType ;
  int get zoom => _zoom ;
  
  void setCenter( GMapLatLong latLong ) {
    this._center = latLong ;
    
    callGMap_setCenter( latLong.latitude , latLong.longitude ) ;
  }
  
  void setMapType(int mapType) {
    callGMap_setMapType(mapType) ;
  }
  
  void setZoom(int zoom) {
    callGMap_setZoom(zoom) ;
  }
  
  void addMarker( GMapLatLong latLong , String title ) {
    callGMap_addMarker( latLong.latitude , latLong.longitude , title ) ;
  }
  
  ////////////////////////////////////////////////////
  
  void callGMap_Command(String type, String param) {
      jsEval("""{
         document.__GMapIframe__iframe_doc.gmapCommand('$type' , ${ param.contains('"') ? "'$param'" : '"$param"' }) ;
      }""") ;
  }
  
  void callGMap_setCenter(double lat, double long) {
      jsEval("""{
         document.__GMapIframe__iframe_doc.gmap_setCenter($lat , $long) ;
      }""") ;
  }
  
  GMapLatLong callGMap_getCenter() {
      JsObject obj = jsEval("""{
         document.__GMapIframe__iframe_doc.gmap_getCenter() ;
      }""") ;
      
      num lat = obj['lat'] ;
      num long = obj['lng'] ;
      
      return new GMapLatLong(lat, long) ;
  }
  
  void callGMap_setMapType(int mapType) {
        jsEval("""{
           document.__GMapIframe__iframe_doc.gmap_setMapType($mapType) ;
        }""") ;
    }
  
  void callGMap_setZoom(int zoom) {
      jsEval("""{
         document.__GMapIframe__iframe_doc.gmap_setZoom($zoom) ;
      }""") ;
  }
  
  void callGMap_addMarker(double lat, double long, String title) {
      jsEval_PARAMS("""{
         document.__GMapIframe__iframe_doc.gmap_addMark($lat,$long, PARAMS[0]) ;
      }""" , [ title ]) ;
  }
  
  ////////////////////////////////////////////////////
  
  String get iframeID => _iframe.id ; 
  
  void _load() {
    _loadIFrameContent() ;
  }
  
  void _loadIFrameContent() {

    Function callBack = (String methodName, params) {
      window.alert('call> $methodName > $params') ;
    };
    
    
    jsEval_PARAMS("""{
       var callBack = PARAMS[0] ;

       document.__GMapIframe__callBack = function(methodName, params) {
          callBack(methodName , params) ;
       };

       var myIframe = document.getElementById('$iframeID') ;
       var iFrameWindow = myIframe.contentWindow || myIframe.documentWindow ;
       var iFrameDoc = iFrameWindow.document ;

       document.__GMapIframe__iframe = myIframe ;
       document.__GMapIframe__iframe_win = iFrameWindow ;
       document.__GMapIframe__iframe_doc = iFrameDoc ;

       iFrameDoc.open() ;

       iFrameDoc.write("<html><head><style type='text/css'> html { height: 100% } body { height: 100%; margin: 0; padding: 0 } #map-canvas { height: 100% } </style><script type='text/javascript' src='https://maps.googleapis.com/maps/api/js?sensor=true'></script>${ _gmapControlJS() }</head><body><div id='map-canvas'/></div></body></html>") ;

       iFrameDoc.close() ;

    }""" , [callBack]) ;
    
  }
  
  void callGMapCommand(String type, String param) {
    jsEval("""{
       document.__GMapIframe__iframe_doc.gmapCommand('$type' , ${ param.contains('"') ? "'$param'" : '"$param"' }) ;
    }""") ;
  }
  
  String _gmapControlJS() {
    String js = """

    <script type='text/javascript'>

      document.gmap_parentDoc = window.parent.document ; 
    
      document.gmapCommand = function(type, param) {
        alert('cmd> '+ type +' ; '+ param);

        document.gmap_parentDoc.__GMapIframe__callBack('mn:'+type , 'ps:'+param) ;
      } ;

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

      document.gmap_addMark = function(lat,long,title) {
        var marker = new google.maps.Marker({
          position: new google.maps.LatLng(lat,long) ,
          map: document.gmap ,
          title: title
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