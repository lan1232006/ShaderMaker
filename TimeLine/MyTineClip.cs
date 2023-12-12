using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

namespace CustomTimeLine
{
    //Clip是用户唯一可配置属性的地方，所有需要的属性都放在这里配置，为什么不放在Data里？因为用户接触不到 它是动态生成的且无法挂载的脚本
    //所以需要在这个脚本里配置 再get出来进行赋值
    //其次Clip是资产类 无法引用其他需要拖曳的资产，它需要通过导演里获取绑定的对象，所以会出现ExposedReference<Transform> tans (它其实获取的是导演下面绑定的)
    public class MyTineClip : PlayableAsset
    {
        public List<MaterialPropertys> properties;//Clip里配置属性 然赋值给data里的propertie
        //在这个脚本里给data里的数据赋值 
        public MyTimeLineData template = new MyTimeLineData();
        //public ExposedReference<Transform> tans;
        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<MyTimeLineData>.Create( graph,  template);
            //获取playable身上的MyTimeLineData；
            MyTimeLineData clone = playable.GetBehaviour(); 
            clone.properties = properties;
            return playable;
        }
    }
}

