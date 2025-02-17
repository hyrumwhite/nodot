@tool
class_name HitScan3D extends Nodot3D

## Detects a hit between the start point end target

## Whether to enable the hitscan or not
@export var enabled: bool = false
## Which raycast to use
@export var raycast: RayCast3D
## The accuracy of the shot (0.0 = 100% accurate)
@export var accuracy : float = 0.0
## How much damage to deal to the target (0.0 to disable)
@export var damage: float = 0.0
## Damage reduction per meter of distance as a percentage (0.0 to disable)
@export var damage_distance_reduction: float = 0.0
## Total distance (meters) to search for hit targets
@export var distance : float = 500
## Reverses the damage to heal instead
@export var healing : bool = false

signal target_hit(hit_target: HitTarget)

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _enter_tree() -> void:
  if raycast and raycast.enabled:
    raycast.target_position = Vector3(0, 0, -distance)

## Execute the hitscan
## TODO: Typehint this when nullable static types are supported. https://github.com/godotengine/godot-proposals/issues/162
func action():
  if enabled:
    if accuracy > 0.0:
      aim_raycast()
    return get_hit_target()

## Point the raycast at the target with a random offset based on accuracy
func aim_raycast() -> void:
  if raycast.enabled:
    var new_x : float = rng.randf_range(-accuracy, accuracy)
    var new_y : float = rng.randf_range(-accuracy, accuracy)
    raycast.target_position = Vector3(new_x, new_y, -distance)
    raycast.force_raycast_update()

## Get the objects that the raycast is colliding with
## TODO: Typehint this when nullable static types are supported. https://github.com/godotengine/godot-proposals/issues/162
func get_hit_target():
  if raycast.enabled and raycast.is_colliding():
    var collider: Node3D = raycast.get_collider()
    if collider:
      var distance : float = get_distance(collider)
      var hit_target = HitTarget.new(distance, raycast.get_collision_point(), raycast.get_collision_normal(), collider)
      # TODO: Apply force
      if damage > 0.0:
        var collider_healths: Array[Node] = collider.find_children("*", "Health")
        if collider_healths.size() > 0:
          var collider_health: Health = collider_healths[0]
          var final_damage: float = damage
          # Calculate damage reduction
          if damage_distance_reduction > 0.0:
            var damage_reduction: float = (final_damage / 100) * damage_distance_reduction
            final_damage = final_damage - (distance * damage_reduction)
          # Apply damage to the hit target
          if !healing:
            final_damage = -final_damage
          collider_health.add_health(final_damage)

      emit_signal("target_hit", hit_target)
      return hit_target

## Returns the distance from the raycast origin to the target
func get_distance(object: Variant) -> float:
  return object.position.distance_to(raycast.get_global_transform().origin)
