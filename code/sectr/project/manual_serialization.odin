package sectr

import "core:encoding/json"
import "core:reflect"

// TODO(Ed) : Generic Unmarshling of json objects (There should be a way I believe todo this generically but the reflect library is not well documented)

vec2_json_unmarshal :: proc( value : ^ json.Value ) -> Vec2 {
	json_v := value.(json.Array)
	return {
		f32(json_v[0].(json.Float)),
		f32(json_v[1].(json.Float)),
	}
}

color_json_unmarshal :: proc( value : ^ json.Value ) -> RGBA8 {
	json_color := value.(json.Array)
	r := u8(json_color[0].(json.Float))
	g := u8(json_color[1].(json.Float))
	b := u8(json_color[2].(json.Float))
	a	:= u8(json_color[3].(json.Float))
	return { r, g, b, a }
}
