"""Render only the new DoubleLuck icon through the established pass pipeline."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import math
import lib
import icon_models as ui
import pass_models as passes
import render_icons as render

def double_luck():
    lib.tube('Golden clover stem', [(.10,0,1.18),(.23,0,.51),(.03,0,.03)], [.12,.10,.065], 'gold')
    for i in range(4):
        a=i*math.pi/2
        points=[]
        for j in range(64):
            t=j*math.tau/64
            x=.032*(16*math.sin(t)**3)
            z=.032*(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))+.46
            points.append((x*math.cos(a)-z*math.sin(a),1.39+x*math.sin(a)+z*math.cos(a)))
        ui.shape('Golden heart leaf', points, .34, 'goldLight' if i%2 else 'gold', rounding=.08)
    lib.sphere('Clover jewel', (0,-.24,1.39), (.19,.12,.19), 'goldLight')
    for sign in (-1,1):
        ui.shape('Ribbon tail', [(sign*.65,.84),(sign*1.12,.88),(sign*.99,.55),(sign*1.12,.21),(sign*.57,.35)], .18, 'blue', rounding=.045)
    passes.badge('2x',0,.62,width=1.65,color='blue',y=-.52)
    passes.sparkle(-1.05,2.40,.20,'white')
    passes.sparkle(1.05,1.70,.16,'white')

passes.MODELS['DoubleLuck']=double_luck
render.install_render_geometry()
render.render_icon('DoubleLuck','passes',96)
