import React from "@rbxts/react";
import { useDelayedUpdate } from "hooks/common/use-delayed-update";
import { useCurrentPage } from "hooks/use-current-page";
import { DashboardPage } from "store/models/dashboard.model";
import Apps from "./Apps";
import Home from "./Home";
import Options from "./Options";
import Scripts from "./Scripts";

function Pages() {
	const currentPage = useCurrentPage();
	const isScriptsVisible = useDelayedUpdate(currentPage === DashboardPage.Scripts, 2000, (isVisible) => isVisible);
	return (
		<>
			<Home key="home" />
			<Apps key="apps" />
			{isScriptsVisible && <Scripts key="scripts" />}
			<Options key="options" />
		</>
	);
}

export default (Pages);
