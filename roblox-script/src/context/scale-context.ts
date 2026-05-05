import React from "@rbxts/react";

export const ScaleContext = React.createContext<React.Binding<number>>(React.createBinding(1)[0]);
