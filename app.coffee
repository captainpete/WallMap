class Mapper
  constructor: ->
    this.initMap()
    @result = ''
    @maxZoom = 18
    @orgZoom = 17
    @tileSize = 640
    @scale = 2
    @padding = 100

  initMap: ->
    latLng = new google.maps.LatLng(-37.8133, 144.9627)
    opts =
      zoom: 17
      center: latLng
      mapTypeId: google.maps.MapTypeId.HYBRID

    @map = new google.maps.Map($('#wm_viewer')[0], opts)

  draw: ->
    @x = 0
    @y = 0
    this.stamp "Entire map", no

    @bounds = @map.getBounds()
    @ne = @bounds.getNorthEast()
    @sw = @bounds.getSouthWest()

    center = new google.maps.LatLng(@ne.lat(), @sw.lng())
    @map.setCenter center
    @map.setZoom @maxZoom
    @map.panBy @tileSize / 2, @tileSize / 2
    
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

    @result = "convert -size #{@xmax * @tileSize * @scale}x#{@ymax * @tileSize * 0.9 * @scale} xc:white \\#{@result}\n wall_map.png"
    $('#wm_result').text(@result)

    @map.setZoom 17
    @map.setCenter @bounds.getCenter()

  over: ->
    !@map.getBounds().intersects(@bounds)

  nextCol: ->
    @map.panBy @tileSize, 0
    @x += 1

  nextRow: ->
    @map.panBy -@tileSize * @x, @tileSize * 0.9
    @y += 1
    @x = 0

  stamp: (message = "Frame", save = yes) ->
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
    console.log "#{message}: #{bounds.toString()}"

    if save
      console.log "Saving #{@x}, #{@y}"
      params = $.param
        sensor: false
        format: 'png'
        maptype: 'hybrid'
        center: @map.getCenter().toUrlValue()
        size: "#{@tileSize}x#{@tileSize}"
        scale: @scale
        zoom: @maxZoom

      styles = [
        "feature:road.arterial|visibility:on|saturation:25|hue:0x33ff00",
        "feature:landscape.man_made|visibility:simplified|hue:0x8800ff|saturation:9|lightness:8",
        "feature:road.highway|visibility:on|saturation:-25|lightness:15|hue:0x9000ff"
      ]
      for style in styles
        params += "&#{$.param(style: style)}"

      url = "http://maps.googleapis.com/maps/api/staticmap?#{params}"

      @result += "\n-draw \"image over #{@x * @tileSize * @scale},#{@y * @tileSize * 0.9 * @scale} 0,0 '#{url}'\" \\"

$ ->
  mapper = new Mapper
  $('#wm_draw_button').click -> mapper.draw()
