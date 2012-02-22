//
//  Shader.fsh
//  Dwarfs
//
//  Created by Jonathan Wight on 09/05/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texture0;

uniform sampler2D u_texture0;
uniform int u_switch;

void main()
    {
	if (u_switch == 0)
		{
		gl_FragColor = texture2D(u_texture0, v_texture0);
		}
	else
		{
		gl_FragColor = vec4(v_texture0.x, 0.0, 0.0, 1.0);
		}
    }
