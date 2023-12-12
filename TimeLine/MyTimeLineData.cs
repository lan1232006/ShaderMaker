using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

namespace CustomTimeLine
{
    public class MyTimeLineData : PlayableBehaviour
    {
        public List<MaterialPropertys> properties;
        
        //TimeLine里的Update 每帧执行  处理逻辑
        public override void ProcessFrame(Playable playable, FrameData info, object playerData)
        {
            //playerData 就是Timeline导演里里绑定的物体   Track里的  [TrackBindingType(typeof(Material))] // 表明这个轨道可以绑定到一个Material类型的对象
            //这里传入的playerData就是 导演里绑定的 Material实例
            var material = playerData as Material;
            if(material == null) return;

            float t = (float)(playable.GetTime() / playable.GetDuration());
            foreach (var propertie in properties)
            {
                Color color =  propertie.gradient.Evaluate(t);
                material.SetColor(propertie.propertyName,color);
                //material.SetTexture();
            }
        }
    }
}

