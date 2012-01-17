class Mapper
  constructor: ->
    this.initMap()
    @result = ''
    @tileSizeX = @mapDiv.innerWidth()
    @tileSizeY = @mapDiv.innerHeight()
    @scale = 2
    @padding = 100
    @overlays = new Array()

  initMap: ->
    latLng = new google.maps.LatLng(-37.8133, 144.9627)
    opts =
      zoom: 17
      center: latLng
      mapTypeId: google.maps.MapTypeId.ROADMAP

    @mapDiv = $('#wm_map')
    @map = new google.maps.Map(@mapDiv[0], opts)

  draw: ->
    for overlay in @overlays
      overlay.setMap(null)

    orgZoom = @map.getZoom()

    @x = 0
    @y = 0
    @detailZoom = $('#wm_detail_zoom').val()
    this.stamp "Entire map", no

    @bounds = @map.getBounds()
    @ne = @bounds.getNorthEast()
    @sw = @bounds.getSouthWest()

    center = new google.maps.LatLng(@ne.lat(), @sw.lng())
    @map.setCenter center
    @map.setZoom parseInt(@detailZoom)
    @map.panBy @tileSizeX / 2, @tileSizeY / 2
    
    @result = ''
    
    loop
      until this.over()
        this.stamp()
        this.nextCol()
      @xmax ?= @x
      this.nextRow()
      if this.over()
        @ymax = @y
        break

    @result = "convert -size #{@xmax * @tileSizeX * @scale}x#{@ymax * @tileSizeY * 0.9 * @scale} xc:white \\#{@result}\n wall_map.png"
    $('#wm_result').text(@result)

    @map.setZoom orgZoom
    @map.setCenter @bounds.getCenter()

  over: ->
    !@map.getBounds().intersects(@bounds)

  nextCol: ->
    @map.panBy @tileSizeX, 0
    @x += 1

  nextRow: ->
    @map.panBy -@tileSizeX * @x, @tileSizeY * 0.9
    @y += 1
    @x = 0

  staticMapType: ->
    switch @map
      when google.maps.MapTypeId.HYBRID then 'hybrid'
      when google.maps.MapTypeId.ROADMAP then 'roadmap'
      when google.maps.MapTypeId.SATELLITE then 'satellite'
      when google.maps.MapTypeId.TERRAIN then 'terrain'
      else 'roadmap'

  stamp: (message = "Frame", shouldSave = yes) ->
    rect = new google.maps.Rectangle()
    bounds = @map.getBounds()
    rect.setOptions
      strokeColor: "#008800",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#008800",
      fillOpacity: 0.15,
      map: @map,
      bounds: bounds
    @overlays.push(rect)
    console.log "#{message}: #{bounds.toString()}"

    this.save() if shouldSave

  save: ->
    @result += "\n-draw \"image over #{@x * @tileSizeX * @scale},#{@y * @tileSizeY * 0.9 * @scale} 0,0 '#{this.currentTileUrl()}'\" \\"

  currentTileUrl: ->
    this.tileUrl(@map.getCenter(), @detailZoom, @tileSizeX, @tileSizeY)

  tileUrl: (center, zoom, width, height) ->
    params = $.param
      sensor: false
      format: 'png'
      maptype: this.staticMapType()
      center: center.toUrlValue()
      size: "#{width}x#{height}"
      scale: @scale
      zoom: zoom

    # styles = [
    #   "feature:road.arterial|visibility:on|saturation:25|hue:0x33ff00",
    #   "feature:landscape.man_made|visibility:simplified|hue:0x8800ff|saturation:9|lightness:8",
    #   "feature:road.highway|visibility:on|saturation:-25|lightness:15|hue:0x9000ff"
    # ]
    # for style in styles
    #   params += "&#{$.param(style: style)}"

    "http://maps.googleapis.com/maps/api/staticmap?#{params}"


$ ->
  $('#wm_controls').html(
    """
      <div id="wm_example_tile">
        <img/>
      </div>

      <h3>Usage</h3>
      <ol>
        <li>Frame the poster using the map window</li>
        <li>Click here to <button id="wm_draw_button">draw the map</button>
        <li>Run the resulting convert command</li>
      </ol>

      <p>
        The image on the left is a small section of the resulting image at full
        scale.  This is the level of detail that will result in the final
        image.
      </p>

      <div class="panel">
        <label for="wm_detail_zoom">Detail Zoom level</label>
        <input id="wm_detail_zoom" type="text">
      </div>
    """
  )

  mapper = new Mapper

  $('#wm_draw_button').click (event) ->
    event.preventDefault()
    mapper.draw()

  updateExample = ->
    map = mapper.map
    src = mapper.tileUrl(map.getCenter(), $('#wm_detail_zoom').val(), 100, 100)
    $('#wm_example_tile img').attr('src', src)

  $('#wm_detail_zoom').change updateExample
  $('#wm_detail_zoom').val(18)
  updateExample()

  $('#wm_result').text(
    """
      The generated command appears here. Example:

      convert -size 3186x2160 xc:white \
      -draw "image over 0,0 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.812452%2C144.961276&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 1062,0 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.812452%2C144.964124&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 2124,0 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.812452%2C144.966973&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 0,720 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.813978%2C144.961276&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 1062,720 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.813978%2C144.964124&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 2124,720 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.813978%2C144.966973&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 0,1440 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.815504%2C144.961276&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 1062,1440 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.815504%2C144.964124&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      -draw "image over 2124,1440 0,0 'http://maps.googleapis.com/maps/api/staticmap?sensor=false&format=png&maptype=hybrid&center=-37.815504%2C144.966973&size=531x400&scale=2&zoom=18&style=feature%3Aroad.arterial%7Cvisibility%3Aon%7Csaturation%3A25%7Chue%3A0x33ff00&style=feature%3Alandscape.man_made%7Cvisibility%3Asimplified%7Chue%3A0x8800ff%7Csaturation%3A9%7Clightness%3A8&style=feature%3Aroad.highway%7Cvisibility%3Aon%7Csaturation%3A-25%7Clightness%3A15%7Chue%3A0x9000ff'" \
      wall_map.png
    """
  )

