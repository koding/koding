class DemosMainView extends KDScrollView

  viewAppended:->
    @addSubView scene = new KDDiaScene

    scene.addSubView container1 = new KDDiaContainer draggable : yes
    scene.addSubView container2 = new KDDiaContainer
    scene.addSubView container3 = new KDDiaContainer draggable : yes

    container1.addSubView diaObject1 = new KDDiaObject type:'square'
    container1.addSubView diaObject2 = new KDDiaObject type:'square'
    container1.addSubView diaObject3 = new KDDiaObject type:'square'

    container2.addSubView diaObject4 = new KDDiaObject type:'circle'
    container2.addSubView diaObject5 = new KDDiaObject type:'circle'
    container2.addSubView diaObject6 = new KDDiaObject type:'square'

    container3.addSubView diaObject7 = new KDDiaObject type:'square'

    scene.connect {dia:diaObject1, joint:'bottom'}, \
                  {dia:diaObject2, joint:'bottom'}
    scene.connect {dia:diaObject2, joint:'top'},    \
                  {dia:diaObject3, joint:'top'}
    scene.connect {dia:diaObject3, joint:'bottom'}, \
                  {dia:diaObject7, joint:'bottom'}
    scene.connect {dia:diaObject3, joint:'right'},  \
                  {dia:diaObject4, joint:'left'}
    scene.connect {dia:diaObject4, joint:'bottom'}, \
                  {dia:diaObject6, joint:'bottom'}
    scene.connect {dia:diaObject6, joint:'top'},    \
                  {dia:diaObject7, joint:'top'}
