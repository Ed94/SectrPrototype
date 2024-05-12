# UI

## Ideal UI_Box processing per-frame

Would be done in this order:

Build Graph Start

0. Parent constructed
1. `ui_box_make()`
2. Prepare layout & style
3. Construct & process children
4. Post-children populated processing
5. Auto-layout box
6. Process signal from children & depdendent events
7. `ui_signal_from_box(box)`
8. Process state dependent on signal
9. ... Eventual Render Pass

Issues:

You want to batch auto-layout to be deferred to the end of the construction for the state graph of the frame.  
Rendering should be handled outside of the update tick asynchronously (at worst case).   
StyleCombo and LayoutCombos are not stored in UI_Box (it would b N * (Style + Layout) per box of memory where N is the number of entries in a combo (right now there is 4) )  
A layout must be choosen before auto-layout occurs and rn the convention is that layout & style are choosen at the end of a signal since it depends on the box's state from the signal.  

Adjusted order:

0. Parent constructed
1. Prepare layout & style beforehand
2. `ui_box_make()`
3. `ui_signal_from_box(box)`
4. Construct & process children
5. Post-children populated processing
6. ... Build Graph End
7. Auto-Layout Pass
8. Eventual Render Pass


