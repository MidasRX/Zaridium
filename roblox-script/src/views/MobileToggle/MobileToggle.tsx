import React from "@rbxts/react";
import { UserInputService } from "@rbxts/services";
import { useAppDispatch, useAppSelector } from "hooks/common/rodux-hooks";
import { useSpring } from "hooks/common/use-spring";
import { hex } from "utils/color3";
import { px } from "utils/udim2";

const SIZE = 44;

// Decided once: hook order and layout must not change while the Hub is running.
const IS_TOUCH = UserInputService.TouchEnabled;

/**
 * On-screen button that opens/closes the dashboard on touch devices, which
 * have no keyboard to press the toggle shortcut with.
 */
function MobileToggle() {
	const dispatch = useAppDispatch();
	const isOpen = useAppSelector((state) => state.dashboard.isOpen);
	const background = useSpring(isOpen ? hex("#2B2F3A") : hex("#0F1117"), {});

	return (
		<textbutton
			Visible={IS_TOUCH}
			Text={isOpen ? "X" : "Z"}
			Font="GothamBlack"
			TextSize={20}
			TextColor3={hex("#FFFFFF")}
			AutoButtonColor={false}
			AnchorPoint={new Vector2(0.5, 0)}
			Position={new UDim2(0.5, 0, 0, 8)}
			Size={px(SIZE, SIZE)}
			BackgroundColor3={background}
			BackgroundTransparency={0.1}
			BorderSizePixel={0}
			ZIndex={100}
			Event={{ Activated: () => dispatch.toggleDashboard() }}
		>
			<uicorner CornerRadius={new UDim(0, 12)} />
			<uistroke Color={hex("#FFFFFF")} Transparency={0.8} Thickness={1} />
		</textbutton>
	);
}

export default MobileToggle;
