extends Resource
class_name MultimeshAnimationData
## Resource that holds data about AnimatedMultiMeshInsatnce3D animation.

## Index of the starting frame.
@export var start_frame : int = 0

## Animation length in frames.
@export var length : int = 0

func _to_string():
	return "<MultimeshAnimationData: Start frame: %d, Length: %d>" % [start_frame, length]
	
func set_values(input_start_frame : int, input_length) -> MultimeshAnimationData:
	start_frame = input_start_frame
	length = input_length
	return self

## Encodes animation data into a custom_data buffer format (Forward+ renderer only).
static func encode_animation_forward_plus(data : MultimeshAnimationData) -> float:
	if data == null:
		return 0.0
	return encode_two_integers_forward_plus(data.start_frame, data.length)

## Decodes a channel from custom_data buffer (Forward+ renderer only)
static func dencode_animation_forward_plus(buffer_channel : float) -> MultimeshAnimationData:
	var values = decode_two_integers_forward_plus(buffer_channel)

	return MultimeshAnimationData.new().set_values(
		values[0],
		values[1]
	)

static func encode_two_integers_forward_plus(integer : int, integer2 : int) -> float:
	var integer_byte_array = PackedByteArray()
	integer_byte_array.resize(4)
	integer_byte_array.encode_u16(0, integer)
	integer_byte_array.encode_u16(2, integer2)
	
	return integer_byte_array.decode_float(0)

static func decode_two_integers_forward_plus(input : float) -> PackedInt64Array:
	var float_byte_array = PackedByteArray()
	float_byte_array.resize(4)
	float_byte_array.encode_float(0, input)
	
	return [float_byte_array.decode_u16(0), float_byte_array.decode_u16(2)]
