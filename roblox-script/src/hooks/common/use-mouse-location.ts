import { useBinding, useEffect } from "@rbxts/react";
import { UserInputService } from "@rbxts/services";

export function useMouseLocation(onChange?: (location: Vector2) => void) {
	const [location, setLocation] = useBinding(UserInputService.GetMouseLocation());

	useEffect(() => {
		const handle = UserInputService.InputChanged.Connect((input) => {
			const kind = input.UserInputType;
			if (kind === Enum.UserInputType.MouseMovement || kind === Enum.UserInputType.Touch) {
				setLocation(new Vector2(input.Position.X, input.Position.Y));
				onChange?.(new Vector2(input.Position.X, input.Position.Y));
			}
		});

		return () => {
			handle.Disconnect();
		};
	}, []);

	return location;
}
