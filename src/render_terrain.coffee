###
# Copyright (C) 2012 jareiko / http://www.jareiko.net/
###

render_terrain = exports? and @ or @render_terrain = {}

class render_terrain.RenderTerrain
  constructor: (@scene, @terrain, @gl) ->
    # We currently grab the terrain source directly. This is not very kosher.
    @geom = null
    return

  update: (camera, delta) ->
    if !@hmapTex? and @terrain.source?
      @hmapTex = new THREE.Texture(
          @terrain.source.hmap,
          null,
          THREE.RepeatWrapping, THREE.RepeatWrapping
      )
    unless @geom
      @geom = @_createGeom()
      obj = @_createImmediateObject()
      obj.material = new THREE.MeshBasicMaterial( { color: Math.random() * 0xffffff, wireframe: false } )
      @scene.add obj
    return

  _createImmediateObject: ->
    class ImmediateObject extends THREE.Object3D
      constructor: (@renderTerrain) ->
        super()
      immediateRenderCallback: (program, gl, frustum) ->
        @renderTerrain._render program, gl, frustum
    return new ImmediateObject @

  _createGeom: ->
    geom = new array_geometry.ArrayGeometry()
    SIZE = 8
    posn = geom.vertexPositionArray
    for y in [0..SIZE]
      for x in [0..SIZE]
        posn.push x, y, 0
    idx = geom.vertexIndexArray
    for y in [0...SIZE]
      for x in [0...SIZE]
        start = y * (SIZE + 1) + x
        idx.push start + 0, start + SIZE + 1, start + 1
        idx.push start + 1, start + SIZE + 2, start + SIZE + 1
    geom.updateOffsets()
    geom.createBuffers @gl
    geom

  _render: (program, gl, frustum) ->
    @geom.render program, gl
    return

  _vertexShader: "
    varying vec2 vUv;
    uniform vec4 offsetRepeat;
    #ifdef USE_SHADOWMAP
    varying vec4 vShadowCoord[ MAX_SHADOWS ];
    uniform mat4 shadowMatrix[ MAX_SHADOWS ];
    #endif
    void main() {
    vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
    vUv = uv * offsetRepeat.zw + offsetRepeat.xy;
    gl_Position = projectionMatrix * mvPosition;
    #ifdef USE_SHADOWMAP
    for( int i = 0; i < MAX_SHADOWS; i ++ ) {
    vShadowCoord[ i ] = shadowMatrix[ i ] * objectMatrix * vec4( position, 1.0 );
    }
    #endif
    }
    "

  _fragmentShader: ""